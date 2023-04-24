resource "aws_iam_role" "federated" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.federated_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "federated_bucket_access" {
  role       = aws_iam_role.federated.id
  policy_arn = aws_iam_policy.target_bucket_access.arn
}

data "aws_iam_openid_connect_provider" "spire" {
  url = "https://${local.spire_issuer}"
}

data "aws_iam_policy_document" "federated_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type = "Federated"
      identifiers = [
        data.aws_iam_openid_connect_provider.spire.arn,
      ]
    }
    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]
    condition {
      test     = "StringEquals"
      variable = "${local.spire_issuer}:aud"
      values = [
        var.audience,
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "${local.spire_issuer}:sub"
      values = [
        "spiffe://${var.spire_trust_domain}/${var.sa_name}",
      ]
    }
  }
}
