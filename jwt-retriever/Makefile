NAME := jwt-retriever

build:
	docker build -t $(NAME) .

load:
	kind load docker-image $(NAME) --name tmzt
