AWS_REGION ?= eu-west-2
OIDC_BUCKET_NAME ?= spire-oidc-bucket

deploy: terraform-apply install-crds create-namespace apply oidc-upload

clean: delete-namespace remove-crds terraform-destroy

terraform-apply:
	cd infra && \
		$(TERRAFORM) init && \
		$(TERRAFORM) apply \
		-var aws_region=$(AWS_REGION) \
		-var oidc_bucket_name=$(OIDC_BUCKET_NAME) \
		-auto-approve

terraform-destroy:
	cd infra && $(TERRAFORM) apply -auto-approve -destroy

install-crds:
	kubectl apply -f config/crds

remove-crds:
	kubectl apply -f config/crds

create-namespace:
	-kubectl create ns spire

delete-namespace:
	-kubectl delete ns spire

apply:
	kubectl label namespace default example=true
	kubectl apply -f config

wait-for-jwks-retriever:
	kubectl wait pods -l app=jwks-retriever --for condition=Ready --timeout=120s

get-jwks: wait-for-jwks-retriever
	kubectl exec $$(kubectl get po -l=app=jwks-retriever -oname) -- sh -c "until [ -f /run/spire/bundle/jwks.json ]; do sleep 5; done"
	kubectl cp $$(kubectl get po -l=app=jwks-retriever -oname | sed 's/pod/default/'):/run/spire/bundle/jwks.json oidc/keys

oidc-upload:  get-jwks ## Configure the oidc discovery provider in aws
	aws s3 cp oidc/keys s3://$(OIDC_BUCKET_NAME)/keys
	aws s3api put-object-acl --bucket $(OIDC_BUCKET_NAME) --key keys --acl public-read
	aws s3 cp oidc/openid-configuration s3://$(OIDC_BUCKET_NAME)/.well-known/openid-configuration
	aws s3api put-object-acl --bucket $(OIDC_BUCKET_NAME) --key .well-known/openid-configuration --acl public-read
