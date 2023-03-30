resource "local_file" "deployment" {
  filename = "${path.module}/../config/deployment.yaml"
  content  = data.template_file.deployment.rendered
}

data "template_file" "deployment" {
  template = file("${path.module}/templates/deployment.yaml")
  vars = {
    sa_name       = var.sa_name
    audience      = var.audience
    aws_region    = var.aws_region
    aws_role      = aws_iam_role.federated.arn
    s3_bucket     = aws_s3_bucket.target.bucket
    s3_object_key = var.s3_object_key
  }
}
