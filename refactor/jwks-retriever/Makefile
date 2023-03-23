NAME := jwks-retriever

build:
	docker build -t $(NAME) .

load:
	kind load docker-image $(NAME) --name tmzt

apply:
	kubectl apply -f config/deployment.yaml

delete:
	-kubectl delete -f config/deployment.yaml

get-jwks:
	kubectl exec $$(kubectl get po -l=app=jwks-retriever -oname) -- sh -c "until [ -f /run/spire/bundle/jwks.json ]; do sleep 5; done"
	kubectl cp $$(kubectl get po -l=app=jwks-retriever -oname | sed 's/pod/default/'):/run/spire/bundle/jwks.json ../oidc/keys

clean:
	rm jwks.json
