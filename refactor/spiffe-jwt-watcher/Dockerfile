FROM golang:1.19-bullseye AS builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY *.go ./
RUN go build -o /spiffe-jwt-watcher
# Create a new release build stage
FROM gcr.io/distroless/base-debian11
WORKDIR /
COPY --from=builder /spiffe-jwt-watcher /spiffe-jwt-watcher
ENTRYPOINT ["/spiffe-jwt-watcher"]