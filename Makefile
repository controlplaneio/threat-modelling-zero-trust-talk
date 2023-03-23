NAME ?= tmzt
KIND_VERSION ?= v0.17.0

ifndef AWS_ACCOUNT_ID
$(error AWS_ACCOUNT_ID is not set)
endif

ifndef AWS_REGION
$(error AWS_REGION is not set)
endif

S3_TARGET_BUCKET_NAME ?= spire-target-bucket
OIDC_BUCKET_NAME ?= spire-oidc-bucket
OPA_POLICY_BUCKET_NAME ?= spire-opa-policy-bucket
SPIRE_TRUST_DOMAIN := $(OIDC_BUCKET_NAME).s3.$(AWS_REGION).amazonaws.com
OIDC_PROVIDER_ARN := arn:aws:iam::$(AWS_ACCOUNT_ID):oidc-provider/$(SPIRE_TRUST_DOMAIN)
BUCKET_POLICY_ARN := arn:aws:iam::$(AWS_ACCOUNT_ID):policy/spire-target-s3-policy
AWS_ROLE_ARN := arn:aws:iam::$(AWS_ACCOUNT_ID):role/spire-target-s3-role
OPA_BUCKET_POLICY_ARN := arn:aws:iam::$(AWS_ACCOUNT_ID):policy/spire-opa-s3-policy
OPA_POLICY_FETCH_ROLE_ARN := arn:aws:iam::$(AWS_ACCOUNT_ID):role/fetch-opa-policy-role

WATCHER_IMAGE_NAME := $(shell uuidgen)
JWT_FETCH_IMAGE_NAME := $(shell uuidgen)

OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m | sed 's/x86_64/amd64/')

THUMBPRINT := $(shell openssl s_client -connect $(SPIRE_TRUST_DOMAIN):443 < /dev/null 2>/dev/null | openssl x509 -fingerprint -noout -in /dev/stdin | cut -d "=" -f2 | sed 's/://g')

.EXPORT_ALL_VARIABLES:

##@ General

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Kind

.PHONY: create-cluster
create-cluster: kind delete-cluster ## Create the kind cluster
	$(KIND) create cluster --name $(NAME) --config kind/kind-cluster.yaml

.PHONY: delete-cluster
delete-cluster: kind ## Delete the kind cluster
	$(KIND) delete cluster --name $(NAME)

.PHONY: kind
KIND = $(shell pwd)/bin/kind
kind: ## Download kind if required
ifeq (,$(wildcard $(KIND)))
ifeq (,$(shell which kind 2> /dev/null))
	echo Downloading Kind
	@{ \
		mkdir -p $(dir $(KIND)); \
		curl -sSLo $(KIND) https://kind.sigs.k8s.io/dl/$(KIND_VERSION)/kind-$(OS)-$(ARCH); \
		chmod + $(KIND); \
	}
else
KIND = $(shell which kind)
endif
endif

##@ AWS

.PHONY: create-target-bucket
create-target-bucket:
	aws s3api create-bucket \
		--bucket $(S3_TARGET_BUCKET_NAME) \
		--region $(AWS_REGION) \
		--create-bucket-configuration LocationConstraint=$(AWS_REGION)
	aws s3 cp aws-resources/test.txt s3://$(S3_TARGET_BUCKET_NAME)/test.txt

.PHONY: create-oidc-bucket
create-oidc-bucket:
	aws s3api create-bucket \
		--bucket $(OIDC_BUCKET_NAME) \
		--region $(AWS_REGION) \
		--acl public-read \
		--create-bucket-configuration LocationConstraint=$(AWS_REGION)

.PHONY: create-opa-policy-bucket
create-opa-policy-bucket:
	aws s3api create-bucket --bucket $(OPA_POLICY_BUCKET_NAME) --create-bucket-configuration LocationConstraint=eu-west-2
	aws s3api put-public-access-block \
		--bucket $(OPA_POLICY_BUCKET_NAME) \
		--public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

.PHONY: create-iam-policy
create-iam-policy:
	envsubst < aws-resources/iam/read-target-bucket-policy.json > aws-resources/iam/applied-target-bucket-policy.json
	aws iam create-policy --policy-name spire-target-s3-policy --policy-document file://./aws-resources/iam/applied-target-bucket-policy.json
	rm aws-resources/iam/applied-target-bucket-policy.json

.PHONY: create-opa-s3-iam-policy
create-opa-s3-iam-policy:
	envsubst < aws-resources/iam/opa-bucket-policy.json > aws-resources/iam/applied-opa-bucket-policy.json
	aws iam create-policy --policy-name spire-opa-s3-policy --policy-document file://./aws-resources/iam/applied-opa-bucket-policy.json
	rm aws-resources/iam/applied-opa-bucket-policy.json

.PHONY: create-federated-role
create-federated-role:
	envsubst < aws-resources/iam/trust-policy.json > aws-resources/iam/applied-trust-policy.json
	aws iam create-role --role-name spire-target-s3-role --assume-role-policy-document file://./aws-resources/iam/applied-trust-policy.json
	rm aws-resources/iam/applied-trust-policy.json

.PHONY: attach-policy
attach-policy:
	aws iam attach-role-policy --role-name spire-target-s3-role --policy-arn $(BUCKET_POLICY_ARN)

.PHONY: create-open-id-connect-provider
create-open-id-connect-provider:
	aws iam create-open-id-connect-provider\
		--url https://$(SPIRE_TRUST_DOMAIN) \
		--thumbprint-list $(THUMBPRINT) \
		--client-id-list spire-test-s3

##@ Spire

.PHONY: install-spire
install-spire: ## Install spire into kind cluster
	kubectl label namespace default example=true
	kubectl apply -f kind/manifests/spire/spire-namespace.yaml
	kubectl apply -f kind/manifests/spire/crds.yaml
	envsubst < kind/manifests/spire/template-spire-controller-manager-config.yaml > kind/manifests/spire/spire-controller-manager-config.yaml
	kubectl create configmap spire-controller-manager-config -n spire --from-file=kind/manifests/spire/spire-controller-manager-config.yaml
	rm kind/manifests/spire/spire-controller-manager-config.yaml
	kubectl apply -f kind/manifests/spire/spiffe-csi-driver.yaml
	kubectl apply -f kind/manifests/spire/spire-controller-manager-webhook.yaml
	envsubst < kind/manifests/spire/spire-server.yaml | kubectl apply -f -
	envsubst < kind/manifests/spire/spire-agent.yaml | kubectl apply -f -

.PHONY: create-cluster-spiffeid
create-cluster-spiffeid:
	envsubst < kind/manifests/spiffe-ids/cluster-spiffe-id.yaml | kubectl apply -f -

.PHONY: show-workload-registrations
show-workload-registrations:
	./scripts/show-spire-entries.sh

.PHONY: create-watcher
create-watcher:
	docker build -t watcher ./golang-watcher
	$(KIND) load docker-image watcher --name $(NAME)
	kubectl apply -f kind/manifests/watcher.yaml

.PHONY: get-keys
get-keys:
	./scripts/get-keys.sh

.PHONY: openid-config-upload
openid-config-upload:
	aws s3 cp aws-resources/keys s3://$(OIDC_BUCKET_NAME)/keys
	aws s3api put-object-acl --bucket $(OIDC_BUCKET_NAME) --key keys --acl public-read
	envsubst < aws-resources/openid-configuration > aws-resources/applied-openid-configuration
	aws s3 cp aws-resources/applied-openid-configuration s3://$(OIDC_BUCKET_NAME)/.well-known/openid-configuration
	rm aws-resources/applied-openid-configuration
	aws s3api put-object-acl --bucket $(OIDC_BUCKET_NAME) --key .well-known/openid-configuration --acl public-read

.PHONY: deploy-aws-cli-pod
deploy-aws-cli-pod:
	docker build -t jwt-fetch ./spiffe-jwt-watcher
	$(KIND) load docker-image jwt-fetch --name $(NAME)
	kubectl apply -f kind/manifests/aws-cli.yaml

.PHONY: fetch-from-bucket
fetch-from-bucket:
	./scripts/fetch-from-bucket.sh

.PHONY: teardown-aws-resources
teardown-aws-resources:
	-aws s3 rm s3://$(S3_TARGET_BUCKET_NAME) --recursive
	-aws s3 rb s3://$(S3_TARGET_BUCKET_NAME)
	-aws s3 rm s3://$(OIDC_BUCKET_NAME) --recursive
	-aws s3 rb s3://$(OIDC_BUCKET_NAME)
	-aws iam detach-role-policy --role-name spire-target-s3-role --policy-arn $(BUCKET_POLICY_ARN)
	-aws iam delete-role --role-name spire-target-s3-role
	-aws iam delete-policy --policy-arn $(BUCKET_POLICY_ARN)
	-aws iam detach-role-policy --role-name fetch-opa-policy-role --policy-arn $(OPA_BUCKET_POLICY_ARN)
	-aws iam delete-role --role-name fetch-opa-policy-role
	-aws iam delete-policy --policy-arn $(OPA_BUCKET_POLICY_ARN)
	-aws iam delete-open-id-connect-provider --open-id-connect-provider-arn $(OIDC_PROVIDER_ARN)
	-aws s3 rm s3://$(OPA_POLICY_BUCKET_NAME) --recursive
	-aws s3 rb s3://$(OPA_POLICY_BUCKET_NAME)

.PHONY: push-policy-bundle
push-policy-bundle:
	mkdir applied-policy
	envsubst < policy/example.rego > applied-policy/example.rego
	opa build --bundle ./applied-policy -o bundle.tar.gz
	rm -rf applied-policy
	aws s3 cp bundle.tar.gz s3://$(OPA_POLICY_BUCKET_NAME)/bundle.tar.gz

.PHONY: create-opa-role
create-opa-role:
	envsubst < aws-resources/iam/opa-trust-policy.json > aws-resources/iam/applied-opa-trust-policy.json
	aws iam create-role --role-name fetch-opa-policy-role --assume-role-policy-document file://./aws-resources/iam/applied-opa-trust-policy.json
	rm aws-resources/iam/applied-opa-trust-policy.json

.PHONY: attach-opa-bucket-policy
attach-opa-bucket-policy:
	aws iam attach-role-policy --role-name fetch-opa-policy-role --policy-arn $(OPA_BUCKET_POLICY_ARN)

.PHONY: install-istio
install-istio:
	envsubst < opa-istio/istio-operator.yaml > opa-istio/applied-istio-operator.yaml
	istioctl install --skip-confirmation -f opa-istio/applied-istio-operator.yaml
	rm opa-istio/applied-istio-operator.yaml

.PHONY: opa-istio-resources
opa-istio-resources:
	envsubst < opa-istio/opa-injection.yaml | kubectl apply -f -
	kubectl apply -f opa-istio/serviceentry.yaml
	kubectl apply -f opa-istio/authz-policy.yaml
	kubectl apply -f opa-istio/authz-policy-2.yaml
	envsubst < opa-istio/opa-istio-configmap.yaml | kubectl apply -f -

.PHONY: deploy-example-workloads
deploy-example-workloads:
	kubectl apply -f kind/manifests/workload-1
	kubectl apply -f kind/manifests/workload-2

.PHONY: check-istio-certs
check-istio-certs:
	./scripts/check-istio-certs.sh

/PHONY: send-example-requests
send-example-requests:
	./scripts/send-requests.sh
