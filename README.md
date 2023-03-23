## Prereqs

```shell
export AWS_ACCESS_KEY_ID=xxx
export AWS_SECRET_ACCESS_KEY=xxx
export AWS_SESSION_TOKEN=xxx
```

## Infra Up

```shell
make create-cluster
make image-build-load-jwks-retriever image-build-load-s3-consumer image-build-load-spiffe-jwt-watcher
make spire-deploy
```

## Example One

Run

```shell
make example-one-deploy
make example-one-logs
```

Cleanup

```shell
make example-one-clean
```

## Example Two

Run

```shell
make kyverno-deploy istio-deploy
make example-two-opa-publish example-two-deploy
make check-istio-certs send-example-requests
```

Clean

```shell
make istio-clean
```

## Infra Down

```shell
make spire-clean delete-cluster
```
