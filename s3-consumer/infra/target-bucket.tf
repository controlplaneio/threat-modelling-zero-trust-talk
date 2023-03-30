resource "aws_s3_bucket" "target" {
  bucket = var.target_bucket_name

  force_destroy = true
}

resource "aws_iam_policy" "target_bucket_access" {
  name   = "${var.target_bucket_name}-access"
  policy = data.aws_iam_policy_document.target_bucket_access.json
}

data "aws_iam_policy_document" "target_bucket_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutAccountPublicAccessBlock",
      "s3:GetAccountPublicAccessBlock",
      "s3:ListAllMyBuckets",
      "s3:ListJobs",
      "s3:CreateJob",
      "s3:ListBucket"
    ]
    resources = [
      "*",
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      aws_s3_bucket.target.arn,
      "${aws_s3_bucket.target.arn}/*",
      "arn:aws:s3:*:*:job/*",
    ]
  }
}

resource "aws_s3_object" "file" {
  bucket = aws_s3_bucket.target.id
  key = var.s3_object_key
  source = "${path.module}/files/ric-flair-woo.gif"
}
