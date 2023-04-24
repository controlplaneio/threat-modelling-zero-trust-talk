deploy: terraform-apply apply

clean: delete terraform-destroy

terraform-apply:
	cd infra && \
		$(TERRAFORM) init && \
		$(TERRAFORM) apply \
		-var spire_trust_domain=$(SPIRE_TRUST_DOMAIN) \
		-auto-approve

terraform-destroy:
	cd infra && $(TERRAFORM) apply -auto-approve -destroy


apply:
	kubectl apply -f config

delete:
	-kubectl delete -f config
