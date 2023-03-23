#!/usr/bin/env bash

set -Eeuxo pipefail

ISTIO_OPERATOR_CONFIG=$(pwd)/istio/istio-operator.yaml

cat <<EOF > $ISTIO_OPERATOR_CONFIG
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: istio-system
spec:
  profile: default
  meshConfig:
    trustDomain: $SPIRE_TRUST_DOMAIN
    extensionProviders:
    - name: "opa.local"
      envoyExtAuthzGrpc:
        service: "local-opa-grpc.local"
        port: "9191"
  values:
    global:
    # This is used to customize the sidecar template
    sidecarInjectorWebhook:
      templates:
        spire: |
          spec:
            containers:
            - name: istio-proxy
              volumeMounts:
              - name: workload-socket
                mountPath: /run/secrets/workload-spiffe-uds
                readOnly: true
            volumes:
              - name: workload-socket
                csi:
                  driver: "csi.spiffe.io"
                  readOnly: true
EOF

CLUSTER_POLICY=$(pwd)/istio/config/opa-injection.yaml

cat <<EOF > $CLUSTER_POLICY
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: inject-sidecar
  annotations:
    policies.kyverno.io/title: Inject Sidecar Container
    policies.kyverno.io/category: Sample
    policies.kyverno.io/subject: Pod,Volume
    policies.kyverno.io/description: >-
      The sidecar pattern is very common in Kubernetes whereby other applications can
      insert components via tacit modification of a submitted resource. This is, for example,
      often how service meshes and secrets applications are able to function transparently.
      This policy injects a sidecar container, initContainer, and volume into Pods that match
      an annotation called `vault.hashicorp.com/agent-inject: true`.
spec:
  rules:
  - name: inject-sidecar
    match:
      resources:
        kinds:
        - Deployment
    mutate:
      patchStrategicMerge:
        spec:
          template:
            metadata:
              annotations:
                (opa-istio-injection): "true"
            spec:
              containers:
              - name: opa-istio
                image: openpolicyagent/opa:latest-istio
                imagePullPolicy: IfNotPresent
                args: [
                  "run",
                  "--server",
                  "--config-file=/config/config.yaml",
                  "--addr=localhost:8181"
                ]
                env:
                - name: AWS_STS_REGIONAL_ENDPOINTS
                  value: regional
                - name: AWS_DEFAULT_REGION
                  value: eu-west-2
                - name: AWS_REGION
                  value: eu-west-2
                - name: AWS_ROLE_ARN
                  value: $OPA_POLICY_FETCH_ROLE_ARN
                - name: AWS_WEB_IDENTITY_TOKEN_FILE
                  value: /svid/token
                volumeMounts:
                - mountPath: /config
                  name: opa-istio-config
                - name: svid
                  mountPath: /svid
                  readOnly: true
              volumes:
              - name: vault-secret
                emptyDir:
                  medium: Memory
              - name: opa-istio-config
                configMap:
                  name: opa-istio-config
              - name: svid
                emptyDir: {}
EOF

CONFIGMAP=$(pwd)/istio/config/opa-istio-configmap.yaml

cat <<EOF > $CONFIGMAP
apiVersion: v1
kind: ConfigMap
metadata:
  name: opa-istio-config
data:
  config.yaml: |
    services:
      s3:
        url: https://$OPA_POLICY_BUCKET_NAME.s3.$AWS_REGION.amazonaws.com
        credentials:
          s3_signing:
            web_identity_credentials:
              aws_region: $AWS_REGION
    bundles:
      policy:
        service: s3
        resource: bundle.tar.gz
    plugins:
      envoy_ext_authz_grpc:
        addr: :9191
        path: istio/authz/allow
    decision_logs:
      console: true
EOF
