NAME := s3-consumer

SPIRE_TRUST_DOMAIN ?= controlplane.io
OIDC_BUCKET_NAME ?= spire-oidc-bucket
S3_TARGET_BUCKET_NAME ?= spire-target-bucket
ROLE_NAME ?= spire-target-s3-role
SA_NAME ?= s3-consumer
AUDIENCE ?= s3-consumer

deploy: terraform-apply apply

clean: delete terraform-destroy

build:
	docker build -t $(NAME) .

load:
	kind load docker-image $(NAME) --name tmzt

terraform-apply:
	cd infra && \
		$(TERRAFORM) init && \
		$(TERRAFORM) apply \
		-var spire_trust_domain=$(SPIRE_TRUST_DOMAIN) \
		-var aws_region=$(AWS_REGION) \
		-var oidc_bucket_name=$(OIDC_BUCKET_NAME) \
		-var target_bucket_name=$(S3_TARGET_BUCKET_NAME) \
		-var role_name=$(ROLE_NAME) \
		-var sa_name=$(SA_NAME) \
		-var audience=$(AUDIENCE) \
		-auto-approve

terraform-destroy:
	cd infra && $(TERRAFORM) apply \
	-var oidc_bucket_name=$(OIDC_BUCKET_NAME) \
	-var target_bucket_name=$(S3_TARGET_BUCKET_NAME) \
	-var role_name=$(ROLE_NAME) \
	-var sa_name=$(SA_NAME) \
	-var audience=$(AUDIENCE) \
	-auto-approve -destroy

apply:
	kubectl apply -f config

delete:
	-kubectl delete -f config
