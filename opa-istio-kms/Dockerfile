FROM golang:1.20.1-alpine3.17 as builder

WORKDIR build

COPY . .

RUN go mod download
RUN go build -o bin/opa-istio ./cmd/opa/

FROM openpolicyagent/opa:latest-istio
COPY --from=builder /go/build/bin/opa-istio /app/opa-istio

ENTRYPOINT ["./opa-istio"]
CMD ["run"]
