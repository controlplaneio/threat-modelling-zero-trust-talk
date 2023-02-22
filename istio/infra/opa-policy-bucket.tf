resource "aws_s3_bucket" "opa_policy" {
  bucket = var.opa_policy_bucket_name

  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "opa_policy" {
  bucket = aws_s3_bucket.opa_policy.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_iam_policy" "opa_policy_access" {
  name   = "${var.opa_policy_bucket_name}-access"
  policy = data.aws_iam_policy_document.opa_policy_access.json
}

data "aws_iam_policy_document" "opa_policy_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "${aws_s3_bucket.opa_policy.arn}/*",
    ]
  }
}
