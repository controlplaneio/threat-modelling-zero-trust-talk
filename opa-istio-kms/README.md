

```shell
go build -o bin/opa-istio ./cmd/opa/

export SIGNING_KEY_ARN=alias/opa-ecc 

./bin/opa-istio build --bundle ./policy \
  --output ./policy/bundle.tar.gz \
  --signing-key $SIGNING_KEY_ARN \
  --signing-alg ES512 \
  --signing-plugin aws-kms
  
tar xzf policy/bundle.tar.gz /.signatures.json

./bin/opa-istio run --bundle \
  --verification-key $SIGNING_KEY_ARN \
  --verification-key-id aws-kms \
  ./policy/bundle.tar.gz
  
  
./bin/opa-istio run --bundle --server \
  --verification-key $SIGNING_KEY_ARN \
  --verification-key-id aws-kms \
  ./policy/bundle.tar.gz 
```

```shell
docker build -t opa:istio .
docker run --rm -v $(pwd)/policy:/policy \
  -e AWS_REGION=eu-west-2 \
  -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
  -e AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN \
  opa:istio build --bundle /policy \
  --output /policy/bundle.tar.gz \
  --signing-key $SIGNING_KEY_ARN \
  --signing-plugin aws-kms
  
docker run --rm -v $(pwd)/policy:/policy \
  -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
  -e AWS_REGION=eu-west-2 \
  -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
  -e AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN \
  opa:istio run --bundle \
  --verification-key $SIGNING_KEY_ARN \
  --verification-key-id aws-kms \
  /policy/bundle.tar.gz
```

https://hub.docker.com/layers/openpolicyagent/opa/latest-istio/images/sha256-bc917f6776ee6fad1af5e21af07fd6c84d44847cbe4f8b4f43da8f080e477690?context=explore
https://github.com/open-policy-agent/opa-envoy-plugin/blob/main/cmd/opa-envoy-plugin/main.go
https://www.openpolicyagent.org/docs/latest/envoy-introduction/