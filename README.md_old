# Threat Modelling Zero Trust - Kind Example

## Dependencies

This example has been tested on Arch Linux, and requires the following tools to run:
- Docker
- Kind
- Kubectl
- Helm
- Istioctl
- An active AWS CLI session

The following environment variables need to be exported for this example to work, as explained in the setup steps below:
- `AWS_REGION`
- `S3_TARGET_BUCKET_NAME`
- `OIDC_BUCKET_NAME`
- `SPIRE_TRUST_DOMAIN`
- `OIDC_PROVIDER_ARN`
- `BUCKET_POLICY_ARN`
- `AWS_ROLE_ARN`
- `OPA_POLICY_BUCKET_NAME`
- `OPA_BUCKET_POLICY_ARN`
- `OPA_POLICY_FETCH_ROLE_ARN`

## Overview

This repo demonstrates how the example architecture from the ControlPlane talk `What can go wrong when you trust nobody? Threat Modelling Zero Trust` can be run locally in a Kind cluster. This allows us to spin up components quickly and easily, with only a small amount of cloud resources required. Understanding each component in more detail by configuring integrations in this manner will ultimately lead to a more comprehensive threat model. 

Two demonstrations are included:
- Demo 1 - Authenticate to AWS from a Pod in our Kind cluster, using an SVID issued by the cluster's SPIRE server;
- Demo 2 - Deploy two workloads in an Istio service mesh, with External Authorisation set up using OPA sidecars. OPA policy bundles are downloaded from an S3 bucket using the technique shown in Demo 1. Istio is integrated with SPIRE, and Rego traffic authorisation policies are based on X.509 SVIDs provided to our workloads via SPIRE.  

## Demo Magic 

This repo contains an easy way to run the example using [Demo Magic](https://github.com/paxtonhare/demo-magic). 

First, authenticate to the AWS CLI and export the following environment variables:

```
export AWS_REGION="<insert region here>"
export AWS_ACCOUNT_ID="<insert AWS Account ID here>"
```

Open the `demo-env-vars.sh` file and chose unique names for the following three S3 buckets:
- `S3_TARGET_BUCKET_NAME`
- `OIDC_BUCKET_NAME`
- `OPA_POLICY_BUCKET_NAME`

Save the file and run:
```
. demo-env-vars.sh
```

You can now walk through the demo by running:
```
./demo-run.sh
```

Keep pressing enter until the demo has run and the teardown steps have completed!

## Demo 1 - AWS Resource Setup

### Target S3 Bucket

This example exercise will involve retrieving a file in a private AWS S3 Bucket from a pod running on a local Kind cluster, using a SPIRE-issued JWT SVID. In order to do this, we will create an IAM OIDC Provider in AWS to facilitate federated access for workloads in our Kind cluster. 

First we need to create an S3 Bucket to hold our private resource. Export a chosen `AWS_REGION` and unique bucket name for the target bucket, create the bucket, and upload a sample text file:
```
export AWS_REGION="<insert region here>"
export S3_TARGET_BUCKET_NAME="<Insert unique name here>"
make create-target-bucket
```

### Public S3 Bucket to Hold OIDC Discovery Data

In a Production scenario, we would use a service such as the [Spire OIDC Discovery Provider](https://github.com/spiffe/spire/blob/main/support/oidc-discovery-provider/README.md) to expose JWT signing keys of our SPIRE server via the `/.well-known/openid-configuration` (for example, as per [SIRE AWS OIDC Authentication](https://spiffe.io/docs/latest/keyless/oidc-federation-aws/)). However, here we only intend to demonstrate how all the underlying pieces fit together for threat modelling purposes. As such, in order to limit the cloud infrastructure required to run this simple example, we will create a publicly readable S3 Bucket to host the `JWKS` and `openid-configuration` files:

```
export OIDC_BUCKET_NAME="<Insert unique name here>"
make create-oidc-bucket
```

Note that because this bucket will host the OIDC discovery information for our SPIRE server, the fully qualified domain name of the bucket will act as the 'Trust Domain' in our example. As such, export the trust domain as an environment variable as this will be used throughout the exercise:

```
export SPIRE_TRUST_DOMAIN="${OIDC_BUCKET_NAME}.s3.${AWS_REGION}.amazonaws.com"
```

Obtain the SHA-1 thumbprint of the bucket's certificate, as this will be needed to create our Identity provider in the next step:

```
sha1_fingerprint=$(openssl s_client -connect ${SPIRE_TRUST_DOMAIN}:443 < /dev/null 2>/dev/null | openssl x509 -fingerprint -noout -in /dev/stdin)
hex_thumbprint=$(cut -d "=" -f2 <<< $sha1_fingerprint)
thumbprint=$(echo $hex_thumbprint | sed 's/://g')
```
### IAM Identity Provider

Create an IAM OIDC Provider which will query the OIDC discovery document contained in our S3 bucket:

```
aws iam create-open-id-connect-provider --url "https://${SPIRE_TRUST_DOMAIN}" --thumbprint-list $thumbprint --client-id-list "spire-test-s3"
```

Note the ARN of the created provider, and export it as an environment variable:

```
export OIDC_PROVIDER_ARN="<insert arn here>"
```

### IAM Policy

Create an IAM policy which grants access to our target S3 Bucket:
```
make create-iam-policy
```

Note the ARN of the created policy, and export it as an environment variable:
```
export BUCKET_POLICY_ARN="<insert arn here>"
```

### IAM Role

Create an IAM role which we will permit an example workload in our cluster to assume via an appropriate trust relationship:

```
make create-federated-role
make attach-policy
```

Note the ARN of the created role, and export it as an environment variable:
```
export AWS_ROLE_ARN="<insert arn here>"
```

## Demo 1 - Kind Cluster Setup

Create a Kind cluster:
```
make create-cluster
```

Deploy the SPIRE Server (along with the SPIRE Controller Manager), Agent (along with the SPIFFE CSI Driver), and associated necessary resources:
```
make install-spire
```

Once the SPIRE Server is up and running, create a ClusterSPIFFEID for our example workloads in the default namespace:
```
make create-cluster-spiffeid
```

This enables automatic workload registration for our workloads. 

### Deploy SVID Watcher

We are going to deploy a watcher service based on the [go-spiffe example](https://github.com/spiffe/go-spiffe/tree/main/v2/examples/spiffe-watcher) which will obtain automatically rotated X.509 SVIDs and JWT Bundles from the SPIFFE Workload API. We will build our watcher image and push to the anonymous, ephemeral Docker image registry, [ttl.sh](https://ttl.sh/):

```
make create-watcher
```

Check that a workload registration was automatically created for the watcher:
```
make show-workload-registrations
```

Once the watcher is running, we can query its logs for the SPIRE server's JWKS:
```
make get-keys
```

We can now upload the keys file and `openid-configuration` to our OIDC discovery S3 Bucket:
```
make openid-config-upload
```

It should be noted that if we were exposing the SPIRE OIDC Discovery Service in a Production environment, we would not need to carry out the above steps, as our AWS OIDC Provider would already be able to access the `openid-configuration` and keys files. 

### Deploy AWS CLI Pod with JWT Watcher Init Container

We have provided a SPIFFE JWT Watcher / Fetcher Golang application which can be run as a sidecar container to fetch a JWT SVID with the correct audience (as per our AWS OIDC Provider configuration), and pass this JWT to an AWS CLI container, which can then be used to retrieve the text file we uploaded to our target S3 Bucket. 

Deploy the AWS CLI Pod with the SPIFFE JWT Watcher (this container will also be built and pushed to ttl.sh):
```
make deploy-aws-cli-pod
```

### Retrieve the Text File

Once the AWS CLI Pod is running, we can exec into the AWS CLI container and retrieve the text file using our SVID retrieved by the init container:
```
make fetch-from-bucket
```

Never gonna let you down! 


## Demo 2 - Configure Istio External Authorisation

Label the default namespace to enable automatic Istio sidecar (Envoy proxy) injection:

```
kubectl label namespace default istio-injection=enabled
```

Install Kyverno in Standalone mode using helm version > 3.2:
```
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install kyverno kyverno/kyverno -n kyverno --create-namespace --set replicaCount=1
```

Choose a unique bucket name and create an S3 bucket to hold OPA policy, and ensure that public access is turned off:
```
export OPA_POLICY_BUCKET_NAME=<insert unique name here>
make create-opa-policy-bucket
```

Build the OPA policy bundle and push to the S3 bucket:
```
make push-policy-bundle
```

Create an IAM policy to allow read access to this policy bucket:
```
make create-opa-s3-iam-policy
```

Note the policy ARN and export as an environment variable:
```
export OPA_BUCKET_POLICY_ARN=<insert arn here>
```

Create an IAM role which will be able to read the OPA policy bucket, and which we will allow two example workloads `workload-1` and `workload-2` to assume, as federated principles through an appropriate trust relationship:
```
make create-opa-role
make attach-opa-bucket-policy
```

Note the role and export as an environment variable:
```
export OPA_POLICY_FETCH_ROLE_ARN=<insert arn here>
```

Install Istio: 
```
make install-istio
```

Create the following resources:
- a Kyverno Cluster Policy to inject an OPA sidecar into pods based on an annotation
- a ServiceEntry to map requests to OPA to localhost:9191 assuming that OPA has been deployed as a sidecar
- an AuthorizationPolicy for each workload, stating that authorization of requests to our workloads should be routed to OPA
- a ConfigMap for the OPA config.
```
make opa-istio-resources
```

Deploy our two sample workloads:

```
make deploy-example-workloads
```

Check that X.509 certificates used by Istio for mTLS have been issued by SPIRE:
```
make check-istio-certs
```

Make some example requests between `workload-1` and `workload-2`, and observe the OPA decision logs to see that our example Rego policy has been respected:
```
make send-example-requests
```

## Teardown

Delete the Kind cluster:
```
make delete-cluster
```

Delete all AWS resources:
```
make teardown-aws-resources
```






