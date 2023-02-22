# Threat Modelling Zero Trust Demo

This repo demonstrates how the example architecture from the ControlPlane talk `What can go wrong when you trust nobody? 
Threat Modelling Zero Trust`, can be run locally in a Kind cluster. This allows us to spin up components quickly and 
easily, with only a small amount of cloud resources required. Understanding each component in more detail by configuring
integrations in this manner will ultimately lead to a more comprehensive threat model.

:warning: This is a proof of concept to support the talk and reinforce the benefits of prototyping early when threat
modelling. You are free to use this code as a starting point but don't run it in a production environment.

Two demonstrations are included:
- Demo 1 - Authenticate to AWS from a Pod in our Kind cluster, using an SVID issued by the cluster's SPIRE server.
- Demo 2 - Deploy two workloads in an Istio service mesh, with External Authorisation set up using OPA sidecars. 
OPA policy bundles are downloaded from an S3 bucket. Istio is integrated with SPIRE, and Rego traffic authorisation 
policies are based on X.509 SVIDs provided to our workloads via SPIRE.

## Prereqs

In order to run the examples, an active set of AWS credentials must be available when running the various commands.

This examples uses a number of S3 Buckets, in order to ensure you get unique names, you set the `NAME` environment
variable to something unique to you.

```shell
export NAME=something-unique-to-you
```

## Infra Up

1. Create a Kind cluster and preload third party images
2. Build and load the various images used in the demo
3. Deploy SPIRE with OIDC Discovery exposed using an S3 Bucket

More details can be found [here](spire/README.md).

```shell
make cluster-up cluster-preload-images
make image-build-load-jwks-retriever \
  image-build-load-s3-consumer \
  image-build-load-jwt-retriever \
  image-build-load-opa-istio-kms
make spire-deploy
```

These are the key components for this deployment: 

* [SPIRE OIDC Bucket](spire/infra/oidc-bucket.tf)
* [SPIRE OIDC Provider](spire/infra/oidc-provider.tf)
* [Templated configuration files](spire/infra/templates)
* [JWKS Retriever](jwks-retriever/main.go)
Available after `make spire-deploy`
* [SPIRE OIDC Discovery Document](spire/oidc/openid-configuration)
* [SPIRE JWKS](spire/oidc/keys)

## Example One

In this scenario an example service retrieves an object from an S3 bucket.

More details can be found [here](s3-consumer/README.md).

1. Deploy the s3-consumer application
2. Verify everything is working
3. Cleanup

```shell
make example-one-deploy
```

[Check](https://localhost:30000/flair)

```shell
make example-one-clean
```

* [Target Bucket](s3-consumer/infra/target-bucket.tf) and access policy
* [Federated Role](s3-consumer/infra/target-bucket-federated-role.tf)
* [S3 Consumer](s3-consumer/main.go) manually exchanging the SPIRE JWT SVID for temporary AWS Credentials
* View the application logs

## Example Two

In this scenario we deploy Istio with SPIRE provided X.509 SVIDs for mTLS and a customised OPA Istio sidecar that uses
our custom bundle signing plugin utilising KMS keys. Kyverno injects the sidecars into the two workloads and the OPA 
sidecar reads the JWT SVID from a shared volume and exchanges this for temporary credentials to access S3 and KMS.

More details can be found [here](opa-istio-kms/README.md).

1. Deploy Kyverno and Istio
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
* [JWT Watcher](jwt-retriever/main.go)
Available after `make istio-deploy`
* [OPA Policy](opa/example.rego) from template

## Infra Down

1. Delete the S3 resources for SPIRE and the Kind cluster

```shell
make spire-clean cluster-down
```
