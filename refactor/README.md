## Prereqs

```shell
export AWS_ACCOUNT_ID=xxx
export AWS_ACCESS_KEY_ID=xxx
export AWS_SECRET_ACCESS_KEY=xxx
export AWS_SESSION_TOKEN=xxx
```

## Infra Up

```shell
make create-resources create-cluster spire-up 
make oidc-get-jwks oidc-upload
```

## Example One

Run
```shell
make example-one-deploy
make example-one-logs
```

## Example Two

Run

```shell
make kyverno-deploy istio-deploy istio-opa-deploy
make example-two-opa-publish example-two-deploy
make check-istio-certs send-example-requests
```

## Infra Down

```shell
make delete-resources delete-cluster
```
