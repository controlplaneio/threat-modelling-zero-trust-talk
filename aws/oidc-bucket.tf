resource "aws_s3_bucket" "oidc" {
  bucket = var.oidc_bucket_name

  force_destroy = true
}

resource "aws_s3_bucket_acl" "oidc" {
  bucket = aws_s3_bucket.oidc.id
  acl    = "public-read"
}