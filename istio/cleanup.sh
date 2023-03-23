#!/usr/bin/env bash

set -Eeuxo pipefail

ISTIO_OPERATOR_CONFIG=$(pwd)/istio/istio-operator.yaml
CLUSTER_POLICY=$(pwd)/istio/config/istio-operator.yaml
CONFIGMAP=$(pwd)/istio/config/opa-istio-configmap.yaml

rm $ISTIO_OPERATOR_CONFIG $CLUSTER_POLICY $CONFIGMAP
