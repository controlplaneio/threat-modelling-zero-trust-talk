AWS_REGION ?= eu-west-2
OIDC_BUCKET_NAME ?= spire-oidc-bucket
OPA_POLICY_BUCKET_NAME ?= spire-opa-policy-bucket

.PHONY: deploy
deploy: terraform-apply install install-opa

.PHONY: clean
clean: terraform-destroy

.PHONY: terraform-apply
terraform-apply:
	cd infra && \
		$(TERRAFORM) init && \
		$(TERRAFORM) apply \
		-var aws_region=$(AWS_REGION) \
		-var oidc_bucket_name=$(OIDC_BUCKET_NAME) \
		-var opa_policy_bucket_name=$(OPA_POLICY_BUCKET_NAME) \
		-var role_name=fetch-opa-policy-role \
		-var audience=spire-test-s3 \
		-var workload_one_sa=workload-1 \
		-var workload_two_sa=workload-2\
		-auto-approve

.PHONY: terraform-destroy
terraform-destroy:
	cd infra && $(TERRAFORM) apply \
	-var aws_region=$(AWS_REGION) \
	-var oidc_bucket_name=$(OIDC_BUCKET_NAME) \
	-var opa_policy_bucket_name=$(OPA_POLICY_BUCKET_NAME) \
	-auto-approve -destroy

.PHONY: install
install:
	$(ISTIOCTL) install --skip-confirmation -f istio-operator.yaml

install-opa:
	kubectl label namespace default istio-injection=enabled
	kubectl apply -f config