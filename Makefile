GITHUB_ORG := controlplaneio
DOCKER_HUB_ORG := controlplane
KIND_VERSION := v0.17.0

WATCHER_IMAGE_NAME := $(shell uuidgen)
JWT_FETCH_IMAGE_NAME := $(shell uuidgen)

.PHONY: delete-cluster
delete-cluster:
	kind delete cluster --name tmzt-local-example

.PHONY: install-kind
install-kind:
	curl -Lo "${HOME}"/kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64
	chmod +x "${HOME}"/kind
	sudo mv "${HOME}"/kind /usr/local/bin/kind

.PHONY: create-cluster
create-cluster: delete-cluster
	kind create cluster --config kind/kind-cluster.yaml

.PHONY: create-target-bucket
create-target-bucket:
	aws s3api create-bucket \
	--bucket "${S3_TARGET_BUCKET_NAME}" \
	--region "${AWS_REGION}" \
	--create-bucket-configuration LocationConstraint="${AWS_REGION}"
	aws s3 cp aws-resources/test.txt s3://"${S3_TARGET_BUCKET_NAME}"/test.txt

.PHONY: create-oidc-bucket
create-oidc-bucket:
	aws s3api create-bucket \
	--bucket "${OIDC_BUCKET_NAME}" \
	--region "${AWS_REGION}" \
	--acl public-read \
	--create-bucket-configuration LocationConstraint="${AWS_REGION}"

.PHONY: create-iam-policy
create-iam-policy:
	envsubst < aws-resources/iam/read-target-bucket-policy.json > aws-resources/iam/applied-target-bucket-policy.json
	aws iam create-policy --policy-name spire-target-s3-policy --policy-document file://./aws-resources/iam/applied-target-bucket-policy.json
	rm aws-resources/iam/applied-target-bucket-policy.json

.PHONY: create-federated-role
create-federated-role:
	envsubst < aws-resources/iam/trust-policy.json > aws-resources/iam/applied-trust-policy.json
	aws iam create-role --role-name spire-target-s3-role --assume-role-policy-document file://./aws-resources/iam/applied-trust-policy.json
	rm aws-resources/iam/applied-trust-policy.json

.PHONY: attach-policy
attach-policy:
	aws iam attach-role-policy --role-name spire-target-s3-role --policy-arn "${BUCKET_POLICY_ARN}"

.PHONY: install-spire
install-spire:
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
	docker build -t ttl.sh/${WATCHER_IMAGE_NAME}:1h ./golang-watcher
	docker push ttl.sh/${WATCHER_IMAGE_NAME}:1h
	WATCHER_IMAGE_TAG="ttl.sh/${WATCHER_IMAGE_NAME}:1h" envsubst < kind/manifests/watcher.yaml | kubectl apply -f -

.PHONY: get-keys
get-keys:
	./scripts/get-keys.sh

.PHONY: openid-config-upload
openid-config-upload:
	aws s3 cp aws-resources/keys s3://"${OIDC_BUCKET_NAME}"/keys
	aws s3api put-object-acl --bucket "${OIDC_BUCKET_NAME}" --key keys --acl public-read
	envsubst < aws-resources/openid-configuration > aws-resources/applied-openid-configuration
	aws s3 cp aws-resources/applied-openid-configuration s3://"${OIDC_BUCKET_NAME}"/.well-known/openid-configuration
	rm aws-resources/applied-openid-configuration
	aws s3api put-object-acl --bucket "${OIDC_BUCKET_NAME}" --key .well-known/openid-configuration --acl public-read

.PHONY: deploy-aws-cli-pod
deploy-aws-cli-pod:
	docker build -t ttl.sh/${JWT_FETCH_IMAGE_NAME}:1h ./spiffe-jwt
	docker push ttl.sh/${JWT_FETCH_IMAGE_NAME}:1h
	JWT_FETCH_IMAGE_TAG="ttl.sh/${JWT_FETCH_IMAGE_NAME}:1h" envsubst < kind/manifests/aws-cli.yaml | kubectl apply -f -

.PHONY: fetch-from-bucket
fetch-from-bucket:
	./scripts/fetch-from-bucket.sh

.PHONY: teardown-aws-resources
teardown-aws-resources:
	aws s3 rm s3://"${S3_TARGET_BUCKET_NAME}" --recursive
	aws s3 rb s3://"${S3_TARGET_BUCKET_NAME}"
	aws s3 rm s3://"${OIDC_BUCKET_NAME}" --recursive
	aws s3 rb s3://"${OIDC_BUCKET_NAME}"
	aws iam detach-role-policy --role-name spire-target-s3-role --policy-arn "${BUCKET_POLICY_ARN}"
	aws iam delete-role --role-name spire-target-s3-role
	aws iam delete-policy --policy-arn "${BUCKET_POLICY_ARN}"
	aws iam delete-open-id-connect-provider --open-id-connect-provider-arn "${OIDC_PROVIDER_ARN}"
	


