resource "aws_kms_key" "rsa" {
  description              = "RSA Key for Signing OPA Bundles"
  key_usage                = "SIGN_VERIFY"
  customer_master_key_spec = "RSA_4096"
  deletion_window_in_days  = 10
}

resource "aws_kms_alias" "rsa" {
  name = "alias/opa-rsa"
  target_key_id = aws_kms_key.rsa.id
}

resource "aws_kms_key" "ecc" {
  description              = "ECC Key for Signing OPA Bundles"
  key_usage                = "SIGN_VERIFY"
  customer_master_key_spec = "ECC_NIST_P521"
  deletion_window_in_days  = 10
}

resource "aws_kms_alias" "ecc" {
  name = "alias/opa-ecc"
  target_key_id = aws_kms_key.ecc.id
}

data "aws_caller_identity" "id" {}

data "aws_iam_policy_document" "key" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [
        data.aws_caller_identity.id.arn,
      ]
    }
    actions = [
      "kms:*",
    ]
    resources = [
      aws_kms_key.rsa.arn,
      aws_kms_key.ecc.arn,
    ]
  }
}

resource "aws_iam_policy" "verify" {
  name = "opa-bundle-verifier"
  policy = data.aws_iam_policy_document.verify.json
}

data "aws_iam_policy_document" "verify" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Verify"
    ]
    resources = [
      aws_kms_key.rsa.arn,
      aws_kms_key.ecc.arn,
    ]
  }
}
