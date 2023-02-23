# Threat Modelling Zero Trust - Kind Example

## Dependencies

This example has been tested on Arch Linux, and requires the following dependencies:
- Docker
- Kind
- Kubectl
- An active AWS CLI session

The following environment variables need to be exported for this example to work, as explained in the setup steps below:
- `AWS_REGION`
- `S3_TARGET_BUCKET_NAME`
- `OIDC_BUCKET_NAME`
- `SPIRE_TRUST_DOMAIN`
- `OIDC_PROVIDER_ARN`
- `BUCKET_POLICY_ARN`
- `AWS_ROLE_ARN`

## AWS Resource Setup

### Target S3 Bucket

This example exercise will involve retrieving a file in a private AWS S3 Bucket from a pod running on a local Kind cluster, using a SPIRE-issued JWT SVID. In order to do this, we will create an IAM Identity Provider in AWS to facilitate federated access for workloads in our Kind cluster. 

First we need to create an S3 Bucket to hold our private resource. Export a chosen `AWS_REGION` and unique bucket name for the target bucket, create the bucket, and upload a sample text file:
```
export AWS_REGION="<insert region here>"
export S3_TARGET_BUCKET_NAME="<Insert unique name here>"
make create-target-bucket
```

### Public S3 Bucket to Hold OIDC Discovery Data

In a Production scenario, we would use a service such as the [Spire OIDC Discovery Provider](https://github.com/spiffe/spire/blob/main/support/oidc-discovery-provider/README.md) to expose JWT signing keys of our SPIRE server via the `/.well-known/openid-configuration` (for example, as per [SIRE AWS OIDC Authentication](https://spiffe.io/docs/latest/keyless/oidc-federation-aws/)). However, here we are only intended in demonstrating how all the underlying pieces fit together for threat modelling purposes. As such, in order to limit the cloud infrastructure required to run this simple example, we will create a publicly readable S3 Bucket to host the `JWKS` and `openid-configuration` files:

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

Create an IAM Identity Provider which will query the OIDC discovery document contained in our S3 bucket:

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

```
make create-federated-role
make attach-policy
```

Note the ARN of the created role, and export it as an environment variable:
```
export AWS_ROLE_ARN="<insert arn here>"
```

## Kind Cluster Setup

Create a Kind cluster:
```
make create
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

### Deploy AWS CLI Pod with JWT Helper Init Container

We have provided a SPIFFE JWT helper Golang application which can be run as an init container to fetch a JWT SVID with the correct audience (as per our AWS OIDC Provider configuration), and pass this JWT to an AWS CLI container, which can then be used to retrieve the text file we uploaded to our target S3 Bucket. 

Deploy the AWS CLI Pod with the SPIFFE JWT Fetcher (this container will also be built and pushed to ttl.sh):
```
make deploy-aws-cli-pod
```

### Retrieve the Text File

Once the AWS CLI Pod is running, we can exec into the AWS CLI container and retrieve the text file using our SVID retrieved by the init container:
```
make fetch-from-bucket
```

Never gonna let you down!

## Teardown

Delete the Kind cluster:
```
make delete-cluster
```

Delete all AWS resources:
```
make teardown-aws-resources
```






