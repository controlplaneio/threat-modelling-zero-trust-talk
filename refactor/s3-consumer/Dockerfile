FROM golang:1.20.1-alpine3.17 as builder

WORKDIR build

COPY . .

RUN go mod download
RUN go build main.go

FROM scratch

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /etc/passwd /etc/passwd
COPY --from=builder /go/build/main /main

USER nobody

ENTRYPOINT ["/main"]
