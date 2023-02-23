#!/bin/bash

set -eo pipefail

kubectl exec -t \
    -n spire \
    -c spire-server spire-server-0 -- \
        /opt/spire/bin/spire-server entry show -socketPath /run/spire/sockets/api.sock