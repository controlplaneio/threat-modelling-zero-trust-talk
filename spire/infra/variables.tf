variable "aws_region" {
  default = "eu-west-2"
}

variable "oidc_bucket_name" {
  default = "spire-oidc"
}

variable "spire_trust_domain" {
  default = "controlplane.io"
}

variable "audience" {
  default = "spire-test-s3"
}
