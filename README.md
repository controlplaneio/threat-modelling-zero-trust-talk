# Threat Modelling Zero Trust Demo

This repo demonstrates how the example architecture from the ControlPlane talk `What can go wrong when you trust nobody? 
Threat Modelling Zero Trust` can be run locally in a Kind cluster. This allows us to spin up components quickly and 
easily, with only a small amount of cloud resources required. Understanding each component in more detail by configuring
ntegrations in this manner will ultimately lead to a more comprehensive threat model.

Two demonstrations are included:
- Demo 1 - Authenticate to AWS from a Pod in our Kind cluster, using an SVID issued by the cluster's SPIRE server;
- Demo 2 - Deploy two workloads in an Istio service mesh, with External Authorisation set up using OPA sidecars. 
OPA policy bundles are downloaded from an S3 bucket using the technique shown in Demo 1. Istio is integrated with SPIRE, 
and Rego traffic authorisation policies are based on X.509 SVIDs provided to our workloads via SPIRE.

## Prereqs

```shell
export AWS_ACCESS_KEY_ID=xxx
export AWS_SECRET_ACCESS_KEY=xxx
export AWS_SESSION_TOKEN=xxx
```

## Infra Up

1. Create a Kind cluster and preload third party images
2. Build and load the various images
3. Deploy SPIRE with OIDC Discovery exposed using an S3 Bucket (don't do this in production)

```shell
make cluster-up cluster-preload-images
make image-build-load-jwks-retriever image-build-load-s3-consumer image-build-load-spiffe-jwt-watcher \
  image-build-load-opa-istio-kms
make spire-deploy
```

* [SPIRE OIDC Bucket](spire/infra/oidc-bucket.tf)
* [SPIRE OIDC Provider](spire/infra/oidc-provider.tf)
* [Templated configuration files](spire/infra/templates)
* [JWKS Retriever](jwks-retriever/main.go)
* [Discovery Document](spire/oidc/openid-configuration)
* [JWKS](spire/oidc/keys)
* Load the Discovery document and the JWKS to S3

## Example One

1. Deploy the s3-consumer application
2. View the logs to see what it's retrieved from S3
3. Cleanup

```shell
make example-one-deploy
make example-one-logs
make example-one-clean
```

* [Target Bucket](s3-consumer/infra/target-bucket.tf) and access policy
* [Federated Role](s3-consumer/infra/target-bucket-federated-role.tf)
* [S3 Consumer](s3-consumer/main.go) manually exchanging the SPIRE JWT SVID for temporary AWS Credentials
* View the application logs

## Example Two

1. Deploy Kyverno and Istio, with ...
2. Sign and publish the OPA Bundle and deploy the example workloads
3. Check the Istio certs are issued by SPIRE
4. Check the communication uses Istio's External Authorisation (and spell it properly)
5. Cleanup

```shell
make kyverno-deploy istio-deploy
make example-two-opa-publish example-two-deploy
make example-two-check-istio-certs
make example-two-send-requests
make example-two-delete istio-clean
```

* [OPA Policy Bucket](istio/infra/opa-policy-bucket.tf)
* [OPA Bundle Signing Keys](istio/infra/opa-signing-keys.tf)
* [OPA Role](istio/infra/opa-role.tf)
* [Templated configuration files](istio/infra/templates)
  * Istio Operator configuration
  * Kyverno policy to inject configured OPA sidecar
  * Istio configuration for loading and verifying the bundles from S3 using KMS and automagic AWS credentials
* [OPA Policy](opa/example.rego) from template
* [JWT Watcher](spiffe-jwt-watcher/main.go)

## Infra Down

1. Delete the S3 resources for SPIRE and the Kind cluster

```shell
make spire-clean cluster-down
```
