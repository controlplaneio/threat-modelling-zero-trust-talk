locals {
  spire_trust_domain = "${var.oidc_bucket_name}.s3.${var.aws_region}.amazonaws.com"
}