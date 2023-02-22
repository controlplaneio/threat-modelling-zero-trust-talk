NAME ?= tmzt
KIND_VERSION ?= v0.17.0
ISTIO_VERSION ?= 1.17.1
HELM_VERSION ?= 3.11.2
TERRAFORM_VERSION ?= 1.4.2
SPIRE_VERSION ?= 1.5.3
KYVERNO_VERSION ?= 1.9.2

AWS_REGION ?= eu-west-2
SPIRE_TRUST_DOMAIN ?= controlplane.io
S3_TARGET_BUCKET_NAME ?= $(NAME)-target
OIDC_BUCKET_NAME ?= $(NAME)-oidc
OPA_POLICY_BUCKET_NAME ?= $(NAME)-opa-policy

CLUSTER_NAME := $(NAME)

OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m | sed 's/x86_64/amd64/')


.EXPORT_ALL_VARIABLES:

##@ General

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-30s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Kind

.PHONY: cluster-up
cluster-up: kind ## Create the kind cluster
	$(KIND) create cluster --name $(CLUSTER_NAME) --config kind.yaml

.PHONY: cluster-down
cluster-down: kind ## Delete the kind cluster
	-$(KIND) delete cluster --name $(CLUSTER_NAME)

.PHONY: cluster-preload-images
cluster-preload-images: kind ## Preload the external images required for the demo
	./scripts/preload-images.sh

##@ Spire

.PHONY: spire-deploy
spire-deploy: ## Create required infrastructure and deploy SPIRE
	$(MAKE) -C spire deploy

.PHONY: spire-clean
spire-clean: ## Clean up SPIRE it's infrastructure
	$(MAKE) -C spire clean

.PHONY: spire-registrations
spire-registrations: ## Show spire registrations
	kubectl exec -n spire -c spire-server spire-server-0 -- \
		/opt/spire/bin/spire-server entry show -socketPath /run/spire/sockets/api.sock

##@ Kyverno

.PHONY: kyverno-deploy
kyverno-deploy: helm ## Deploy kyverno
	$(HELM) repo add kyverno https://kyverno.github.io/kyverno/
	$(HELM) repo update
	-$(HELM) install kyverno kyverno/kyverno -n kyverno --create-namespace --set replicaCount=1

##@ Istio

.PHONY: istio-deploy
istio-deploy: istio ## Create required infrastructure and deploy Istio
	$(MAKE) -C istio deploy

.PHONY: istio-clean
istio-clean: ## Clean up Infra it's infrastructure
	$(MAKE) -C istio clean

##@ Example One

.PHONY: example-one-deploy
example-one-deploy: ## Deploy the S3 consumer application
	$(MAKE) -C s3-consumer deploy

.PHONY: example-one-clean
example-one-clean: ## Delete the S3 consumer application
	$(MAKE) -C s3-consumer clean

.PHONY: example-one-logs
example-one-logs: ## Show the logs from the S3 consumer application
	kubectl logs -l app=s3-consumer

##@ Example Two

.PHONY: example-two-opa-publish
example-two-opa-publish: example-two-opa-clean ## Sign and publish OPA bundle
	$(MAKE) -C opa-istio-kms build-cmd
	./opa-istio-kms/bin/opa-istio-kms build --bundle ./opa -o bundle.tar.gz \
		--signing-key alias/opa-ecc \
		--signing-alg ES512 \
		--signing-plugin aws-kms
	aws s3 cp bundle.tar.gz s3://$(OPA_POLICY_BUCKET_NAME)/bundle.tar.gz

.PHONY: example-two-opa-clean ## Delete OPA bundle
example-two-opa-clean:
	-rm bundle.tar.gz

.PHONY: example-two-validate-signature
example-two-validate-signature: ## Validate OPA bundle signature
	./opa-istio-kms/bin/opa-istio run --bundle \
  --verification-key alias/opa-ecc \
  --verification-key-id aws-kms \
  ./bundle.tar.gz

.PHONY: example-two-deploy
example-two-deploy: ## Deploy workloads for Istio and OPA example
	$(MAKE) -C workload-1 apply
	$(MAKE) -C workload-2 apply

.PHONY: example-two-delete
example-two-delete: example-two-opa-clean ## Delete workloads for Istio and OPA example
	$(MAKE) -C workload-1 delete
	$(MAKE) -C workload-2 delete

.PHONY: example-two-check-istio-certs
example-two-check-istio-certs: ## Show Istio issued certificates
	./scripts/check-istio-certs.sh

/PHONY: example-two-send-requests
example-two-send-requests: ## Send requests and show OPA decisions
	./scripts/send-requests.sh

##@ Images

image-build-load-%:
	$(MAKE) -C $* build load

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
