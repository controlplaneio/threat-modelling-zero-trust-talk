NAME ?= tmzt
KIND_VERSION ?= v0.17.0
ISTIO_VERSION ?= 1.17.1
HELM_VERSION ?= 3.11.2
TERRAFORM_VERSION ?= 1.4.2

AWS_REGION ?= eu-west-2
S3_TARGET_BUCKET_NAME ?= spire-target-bucket
OIDC_BUCKET_NAME ?= spire-oidc-bucket
OPA_POLICY_BUCKET_NAME ?= spire-opa-policy-bucket

OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m | sed 's/x86_64/amd64/')
SPIRE_TRUST_DOMAIN := $(OIDC_BUCKET_NAME).s3.$(AWS_REGION).amazonaws.com
THUMBPRINT := $(shell openssl s_client -connect $(SPIRE_TRUST_DOMAIN):443 < /dev/null 2>/dev/null | openssl x509 -fingerprint -noout -in /dev/stdin | cut -d "=" -f2 | sed 's/://g')

##@ General

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ AWS

create-resources: terraform
	cd aws && $(TERRAFORM) apply \
		-var aws_region=$(AWS_REGION) \
		-var target_bucket_name=$(S3_TARGET_BUCKET_NAME) \
		-var oidc_bucket_name=$(OIDC_BUCKET_NAME) \
		-var opa_policy_bucket_name=$(OPA_POLICY_BUCKET_NAME) \
		-var thumbprint=$(THUMBPRINT) \
		-auto-approve

delete-resources: terraform
	cd aws && $(TERRAFORM) apply -auto-approve -destroy

##@ Kind

.PHONY: create-cluster
create-cluster: kind delete-cluster ## Create the kind cluster
	$(KIND) create cluster --name $(NAME) --config kind.yaml

.PHONY: delete-cluster
delete-cluster: kind ## Delete the kind cluster
	-$(KIND) delete cluster --name $(NAME)

##@ Spire

.PHONY: spire-up
spire-up: spire-crds spire-deploy

.PHONY: spire-crds
spire-crds: ## Apply the spire crds
	kubectl apply -f spire/config/crds

.PHONY: spire-deploy
spire-deploy: ## Deploy the spire cluster
	kubectl label namespace default example=true
	-kubectl create ns spire
	kubectl apply -f spire/config

.PHONY: spire-agent-wait-for
spire-agent-wait-for: ## Wait for the spire agent to be ready
	kubectl wait pods -n spire -l app=spire-agent --for condition=Ready --timeout=120s

spire-registrations: ## Show spire registrations
	kubectl exec -n spire -c spire-server spire-server-0 -- \
		/opt/spire/bin/spire-server entry show -socketPath /run/spire/sockets/api.sock

spire-cleanup: ## Delete the spire cluster and remove the templated configuration files
	kubectl delete ns spire
	./spire/cleanup.sh

##@ Kyverno

.PHONY: kyverno-deploy
kyverno-deploy: kind ## Deploy kyverno
	$(HELM) repo add kyverno https://kyverno.github.io/kyverno/
	$(HELM) repo update
	-$(HELM) install kyverno kyverno/kyverno -n kyverno --create-namespace --set replicaCount=1

##@ Istio

.PHONY: istio-deploy
istio-deploy: istio  ## Deploy istio
	$(ISTIOCTL) install --skip-confirmation -f istio/istio-operator.yaml

istio-opa-deploy:
	kubectl label namespace default istio-injection=enabled
	kubectl apply -f istio/config

##@ OIDC

oidc-get-jwks: workload-deploy-jwks-retriever workload-wait-for-jwks-retriever ## Retrieve the jwks
	$(MAKE) -C jwks-retriever get-jwks

oidc-upload:  ## Configure the oidc discovery provider in aws
	aws s3 cp oidc/keys s3://$(OIDC_BUCKET_NAME)/keys
	aws s3api put-object-acl --bucket $(OIDC_BUCKET_NAME) --key keys --acl public-read
	aws s3 cp oidc/openid-configuration s3://$(OIDC_BUCKET_NAME)/.well-known/openid-configuration
	aws s3api put-object-acl --bucket $(OIDC_BUCKET_NAME) --key .well-known/openid-configuration --acl public-read

##@ Example One

example-one-deploy: workload-deploy-s3-consumer ## Deploy workload for example one

example-one-logs:
	kubectl logs -l app=s3-consumer

##@ Example Two

example-two-opa-publish:
	opa build --bundle ./opa -o bundle.tar.gz
	aws s3 cp bundle.tar.gz s3://$(OPA_POLICY_BUCKET_NAME)/bundle.tar.gz

example-two-deploy:
	$(MAKE) -C spiffe-jwt-watcher build load
	$(MAKE) -C workload-1 apply
	$(MAKE) -C workload-2 apply

.PHONY: check-istio-certs
check-istio-certs:
	./scripts/check-istio-certs.sh

/PHONY: send-example-requests
send-example-requests:
	./scripts/send-requests.sh

##@ Workloads

workload-spiffe-config: ## Create configmap with spiffe config for workloads
	-kubectl create configmap spiffe-config \
		--from-literal=SPIFFE_ENDPOINT_SOCKET=unix:///spire-agent-socket/socket \
		--from-literal=TRUST_DOMAIN=$(SPIRE_TRUST_DOMAIN)

workload-deploy-%: workload-spiffe-config ## Build load and apply the workload
	$(MAKE) -C $* build load apply

workload-wait-for-%:
	kubectl wait pods -l app=$* --for condition=Ready --timeout=120s

workload-delete-%:
	$(MAKE) -C $* delete

workload-clean-%:
	$(MAKE) -C $* clean

##@ Tools

.PHONY: kind
KIND = $(shell pwd)/bin/kind
kind: ## Download kind if required
ifeq (,$(wildcard $(KIND)))
ifeq (,$(shell which kind 2> /dev/null))
	@{ \
		mkdir -p $(dir $(KIND)); \
		curl -sSLo $(KIND) https://kind.sigs.k8s.io/dl/$(KIND_VERSION)/kind-$(OS)-$(ARCH); \
		chmod + $(KIND); \
	}
else
KIND = $(shell which kind)
endif
endif

.PHONY: istioctl
ISTIOCTL = $(shell pwd)/bin/istioctl
istioctl: ## Download istioctl if required
ifeq (,$(wildcard $(ISTIOCTL)))
ifeq (,$(shell which istioctl 2> /dev/null))
	@{ \
		mkdir -p $(dir $(ISTIOCTL)); \
		curl -sSLo $(dir $(ISTIOCTL))/istio.tar.gz https://github.com/istio/istio/releases/download/$(ISTIO_VERSION)/istio-$(ISTIO_VERSION)-$(OS)-$(ARCH).tar.gz; \
		tar -xzf $(dir $(ISTIOCTL))/istio.tar.gz ;\
		mv istio-$(ISTIO_VERSION)/bin/istioctl $(dir $(ISTIOCTL)); \
		rm -rf istio-$(ISTIO_VERSION) $(dir $(ISTIOCTL))/istio.tar.gz; \
		chmod + $(ISTIOCTL); \
	}
else
ISTIOCTL = $(shell which istioctl)
endif
endif

.PHONY: helm
HELM = $(shell pwd)/bin/helm
helm: ## Download helm if required
ifeq (,$(wildcard $(HELM)))
ifeq (,$(shell which helm 2> /dev/null))
	@{ \
		mkdir -p $(dir $(HELM)); \
		curl -sSLo $(HELM).tar.gz https://get.helm.sh/helm-v$(HELM_VERSION)-$(OS)-$(ARCH).tar.gz; \
		tar -xzf $(HELM).tar.gz --one-top-level=$(dir $(HELM)) --strip-components=1; \
		chmod + $(HELM); \
	}
else
HELM = $(shell which helm)
endif
endif

.PHONY: terraform
TERRAFORM = $(shell pwd)/bin/terraform
terraform: ## Download terraform if required
ifeq (,$(wildcard $(TERRAFORM)))
ifeq (,$(shell which terraform 2> /dev/null))
	@{ \
		mkdir -p $(dir $(TERRAFORM)); \
		curl -sSLo $(TERRAFORM).tar.gz https://releases.hashicorp.com/terraform/$(TERRAFORM_VERSION)/terraform_$(TERRAFORM_VERSION)_$(OS)_$(ARCH).zip; \
		unzip $(TERRAFORM).tar.gz; \
		mv terraform $(dir $(TERRAFORM)); \
		chmod + $(TERRAFORM); \
	}
else
TERRAFORM = $(shell which terraform)
endif
endif
