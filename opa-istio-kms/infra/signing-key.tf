resource "aws_kms_key" "key" {
  description              = var.key_name
  key_usage                = "SIGN_VERIFY"
  customer_master_key_spec = "RSA_4096"
  policy                   = data.aws_iam_policy_document.key.json
  deletion_window_in_days  = 10
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
      "*",
    ]
  }
  #  statement {
  #    effect = "Allow"
  #    principals {
  #      type = "Federated"
  #      identifiers = [
  #
  #      ]
  #    }
  #    actions = [
  #      "kms:*",
  #    ]
  #    resources = [
  #      aws_kms_key.key.arn,
  #    ]
  #  }
}

output "key_arn" {
  value = aws_kms_key.key.arn
}
