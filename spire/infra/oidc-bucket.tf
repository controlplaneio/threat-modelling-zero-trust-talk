resource "aws_s3_bucket" "oidc" {
  bucket = var.oidc_bucket_name

  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "oidc" {
  bucket = aws_s3_bucket.oidc.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "oidc" {
  bucket = aws_s3_bucket.oidc.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "oidc" {
  bucket = aws_s3_bucket.oidc.id
  acl    = "public-read"

  depends_on = [
    aws_s3_bucket_public_access_block.oidc,
  ]
}
