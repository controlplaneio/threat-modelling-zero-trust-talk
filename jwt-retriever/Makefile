CLUSTER_NAME ?= tmzt
IMAGE_NAME := jwt-retriever

build:
	docker build -t $(IMAGE_NAME) .

load:
	kind load docker-image $(IMAGE_NAME) --name $(CLUSTER_NAME)
