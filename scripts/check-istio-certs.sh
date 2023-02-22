#!/bin/bash

set -eo pipefail

WORKLOAD_POD=$(kubectl get pod -l app=workload-1 -o jsonpath="{.items[0].metadata.name}")
istioctl proxy-config secret ${WORKLOAD_POD}  -o json | jq -r \
	'.dynamicActiveSecrets[0].secret.tlsCertificate.certificateChain.inlineBytes' | base64 --decode > chain.pem
openssl x509 -in chain.pem -text | grep ControlPlane
rm chain.pem