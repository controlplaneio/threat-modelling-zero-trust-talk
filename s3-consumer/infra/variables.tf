variable "aws_region" {
  default = "eu-west-2"
}

variable "spire_trust_domain" {
  default = "controlplane.io"
}

variable "oidc_bucket_name" {
  default = "spire-oidc-bucket"
}

variable "target_bucket_name" {
  default = "spire-target-bucket"
}

variable "s3_object_key" {
  default = "woo"
}

variable "role_name" {
  default = "spire-target-s3-role"
}

variable "sa_name" {
  default = "s3-consumer"
}

variable "audience" {
  default = "s3-consumer"
}
