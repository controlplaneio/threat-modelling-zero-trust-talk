FROM golang:1.19-bullseye AS builder
WORKDIR /app
COPY go.* ./
RUN go mod download
COPY *.go ./
RUN go build -o /jwt-retriever
# Create a new release build stage
FROM gcr.io/distroless/base-debian11
WORKDIR /
COPY --from=builder /jwt-retriever /jwt-retriever
ENTRYPOINT ["/jwt-retriever"]