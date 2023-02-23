#!/bin/bash

set -eo pipefail

POD=$(kubectl get pod -l app=watcher -o jsonpath="{.items[0].metadata.name}")
JWT_LOG=$(kubectl logs ${POD} | grep "jwt bundle updated")
KEYS=$(echo "$JWT_LOG" | sed 's/: /\n/g' | sed -n 2p)
echo "$KEYS" | tee ./aws-resources/keys