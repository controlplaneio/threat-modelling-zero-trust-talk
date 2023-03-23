#!/bin/bash

set -eo pipefail

WORKLOAD_1_POD=$(kubectl get pod -l app=workload-1 -o jsonpath="{.items[0].metadata.name}")
WORKLOAD_1_IP=$(kubectl get service/workload-1 -o jsonpath='{.spec.clusterIP}')
WORKLOAD_2_POD=$(kubectl get pod -l app=workload-2 -o jsonpath="{.items[0].metadata.name}")
WORKLOAD_2_IP=$(kubectl get service/workload-2 -o jsonpath='{.spec.clusterIP}')

echo "Curling /version of workload-2 from workload 1"
kubectl exec -it ${WORKLOAD_1_POD} -c podinfo -- curl ${WORKLOAD_2_IP}:9898/version > /dev/null
echo "Curling /metrics of workload-2 from workload 1"
kubectl exec -it ${WORKLOAD_1_POD} -c podinfo -- curl ${WORKLOAD_2_IP}:9898/metrics > /dev/null
echo "Curling /version of workload-1 from workload 2"
kubectl exec -it ${WORKLOAD_2_POD} -c podinfo -- curl ${WORKLOAD_1_IP}:9898/version > /dev/null
echo "Curling /metrics of workload-1 from workload 2"
kubectl exec -it ${WORKLOAD_2_POD} -c podinfo -- curl ${WORKLOAD_1_IP}:9898/metrics > /dev/null

echo "OPA denied request paths to workload-1:"
kubectl logs ${WORKLOAD_1_POD} | grep "decision_id" | grep '"result":false' | jq '.input.attributes.request.http.path'

echo "OPA allowed request paths to workload-1:"
kubectl logs ${WORKLOAD_1_POD} | grep "decision_id" | grep '"result":true' | jq '.input.attributes.request.http.path'

echo "OPA denied request paths to workload-2:"
kubectl logs ${WORKLOAD_2_POD} | grep "decision_id" | grep '"result":false' | jq '.input.attributes.request.http.path'

echo "OPA allowed request paths to workload-2:"
kubectl logs ${WORKLOAD_2_POD} | grep "decision_id" | grep '"result":true' | jq '.input.attributes.request.http.path'
