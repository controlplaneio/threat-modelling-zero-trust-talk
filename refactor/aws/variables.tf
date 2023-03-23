variable "aws_region" {
  default = "eu-west-2"
}

variable "target_bucket_name" {
  default = "spire-target-bucket"
}

variable "s3_consumer_sa" {
  default = "aws-cli"
}

variable "federated_role_name" {
  default = "spire-target-s3-role"
}

variable "oidc_bucket_name" {
  default = "spire-oidc-bucket"
}

variable "audience" {
  default = "spire-test-s3"
}

variable "thumbprint" {
  default = "014C503E744588C6013CEC3759E33C3FC1BC3283"
}

variable "opa_policy_bucket_name" {
  default = "spire-opa-policy-bucket"
}

variable "opa_role_name" {
  default = "fetch-opa-policy-role"
}

variable "workload_one_sa" {
  default = "workload-1"
}

variable "workload_two_sa" {
  default = "workload-2"
}
