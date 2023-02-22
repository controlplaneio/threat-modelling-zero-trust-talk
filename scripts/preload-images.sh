#!/usr/bin/env bash

set -Eeuxo pipefail

for image in docker.io/istio/pilot:$ISTIO_VERSION \
  docker.io/istio/proxyv2:$ISTIO_VERSION \
  docker.io/stefanprodan/podinfo:latest \
  gcr.io/spiffe-io/spire-agent:$SPIRE_VERSION \
  gcr.io/spiffe-io/spire-server:$SPIRE_VERSION \
  gcr.io/spiffe-io/wait-for-it:latest \
  ghcr.io/kyverno/cleanup-controller:v$KYVERNO_VERSION \
  ghcr.io/kyverno/kyverno:v$KYVERNO_VERSION \
  ghcr.io/kyverno/kyvernopre:v$KYVERNO_VERSION \
  ghcr.io/spiffe/spiffe-csi-driver:0.2.0 \
  ghcr.io/spiffe/spire-controller-manager:nightly \
  registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.4.0
do
  docker pull $image
  $KIND load docker-image $image --name $CLUSTER_NAME
done
