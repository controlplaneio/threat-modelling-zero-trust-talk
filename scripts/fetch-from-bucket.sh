#!/bin/bash

set -eo pipefail

CLI_POD=$(kubectl get pod -l app=aws-cli -o jsonpath="{.items[0].metadata.name}")
kubectl exec -it ${CLI_POD} -- /bin/bash -c "AWS_REGION=${AWS_REGION} \
	AWS_ROLE_ARN=${AWS_ROLE_ARN} \
	AWS_EC2_METADATA_DISABLED=true \
	AWS_WEB_IDENTITY_TOKEN_FILE=/svid/jwt.txt \
	aws s3 cp s3://${S3_TARGET_BUCKET_NAME}/test.txt test.txt && cat test.txt"