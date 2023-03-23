NAME := s3-consumer

build:
	docker build -t $(NAME) .

load:
	kind load docker-image $(NAME) --name tmzt

apply:
	kubectl apply -f config

delete:
	-kubectl delete -f config
