CLUSTER_NAME ?= tmzt
IMAGE_NAME := opa-istio-kms

build:
	docker build -t $(IMAGE_NAME) .

load:
	kind load docker-image $(IMAGE_NAME) --name $(CLUSTER_NAME)

build-cmd:
	go build -o bin/opa-istio-kms ./cmd/opa/
