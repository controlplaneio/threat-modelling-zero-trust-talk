variable "aws_region" {
  default = "eu-west-2"
}

variable "oidc_bucket_name" {
  default = "spire-oidc"
}

variable "spire_trust_domain" {
  default = "controlplane.io"
}

variable "audiences" {
  default = [
    "s3-consumer",
    "opa-istio",
  ]
}
