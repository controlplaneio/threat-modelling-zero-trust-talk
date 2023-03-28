variable "aws_region" {
  default = "eu-west-2"
}

variable "oidc_bucket_name" {
  default = "spire-oidc-bucket"
}

variable "target_bucket_name" {
  default = "spire-target-bucket"
}

variable "role_name" {
  default = "spire-target-s3-role"
}

variable "sa_name" {
  default = "aws-cli"
}

variable "audience" {
  default = "spire-test-s3"
}