variable "aws_region" {
  default = "eu-west-2"
}

variable "spire_trust_domain" {
  default = "controlplane.io"
}

variable "oidc_bucket_name" {
  default = "spire-oidc-bucket"
}

variable "opa_policy_bucket_name" {
  default = "spire-opa-policy-bucket"
}

variable "role_name" {
  default = "fetch-opa-policy-role"
}

variable "audience" {
  default = "spire-test-s3"
}

variable "workload_one_sa" {
  default = "workload-1"
}

variable "workload_two_sa" {
  default = "workload-2"
}
