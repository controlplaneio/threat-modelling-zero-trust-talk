#!/bin/bash

########################
# include the magic
########################
. demo-magic.sh

# hide the evidence
clear

# set up AWS resources
pe "make create-target-bucket"
pe "make create-oidc-bucket"
pe "make create-open-id-connect-provider"
pe "make create-iam-policy"
pe "make create-federated-role"
pe "make attach-policy"

# set up cluster and spire
pe "make create-cluster"
pe "make install-spire"
pe "kubectl wait pods -n spire -l app=spire-agent --for condition=Ready --timeout=120s"
pe "make create-cluster-spiffeid"

# deploy watcher and aws-cli pod
pe "make create-watcher"
pe "kubectl wait pods -n default -l app=watcher --for condition=Ready --timeout=120s"
pe "make show-workload-registrations"
pe "make get-keys"
pe "make openid-config-upload"
pe "make deploy-aws-cli-pod"
pe "kubectl wait pods -n default -l app=aws-cli --for condition=Ready --timeout=120s"
pe "make fetch-from-bucket"

# configure istio external authZ

pe "kubectl label namespace default istio-injection=enabled"
pe "helm repo add kyverno https://kyverno.github.io/kyverno/ && helm repo update && helm install kyverno kyverno/kyverno -n kyverno --create-namespace --set replicaCount=1"
pe "make create-opa-policy-bucket"
pe "make push-policy-bundle"
pe "make create-opa-s3-iam-policy"
pe "make create-opa-role"
pe "make attach-opa-bucket-policy"
pe "make install-istio"
pe "make opa-istio-resources"
pe "make deploy-example-workloads"
pe "kubectl wait pods -n default -l app=workload-2 --for condition=Ready --timeout=120s"
pe "make check-istio-certs"
pe "make send-example-requests"
pe "make delete-cluster"
pe "make teardown-aws-resources"

