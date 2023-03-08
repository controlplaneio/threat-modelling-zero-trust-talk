# environment variables
# please export AWS_ACCOUNT_ID before running this demo
if [[ -z "${AWS_ACCOUNT_ID}" ]]; then
  echo "Please set AWS_ACCOUNT_ID"
fi
if [[ -z "${AWS_REGION}" ]]; then
  echo "Please set AWS_REGION"
fi
export S3_TARGET_BUCKET_NAME=spire-target-bucket
export OIDC_BUCKET_NAME=spire-oidc-bucket
export SPIRE_TRUST_DOMAIN="${OIDC_BUCKET_NAME}.s3.${AWS_REGION}.amazonaws.com"
export sha1_fingerprint=$(openssl s_client -connect ${SPIRE_TRUST_DOMAIN}:443 < /dev/null 2>/dev/null | openssl x509 -fingerprint -noout -in /dev/stdin)
export hex_thumbprint=$(cut -d "=" -f2 <<< $sha1_fingerprint)
export thumbprint=$(echo $hex_thumbprint | sed 's/://g')
export OIDC_PROVIDER_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/${SPIRE_TRUST_DOMAIN}"
export BUCKET_POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/spire-target-s3-policy"
export AWS_ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/spire-target-s3-role"
export OPA_POLICY_BUCKET_NAME=spire-opa-policy-bucket
export OPA_BUCKET_POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/spire-opa-s3-policy"
export OPA_POLICY_FETCH_ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/fetch-opa-policy-role"