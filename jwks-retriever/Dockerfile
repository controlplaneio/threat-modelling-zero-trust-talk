FROM golang:1.20.1-alpine3.17 as builder

WORKDIR build

COPY . .

RUN go mod download
RUN go build main.go

USER nobody

ENTRYPOINT ["/go/build/main"]
