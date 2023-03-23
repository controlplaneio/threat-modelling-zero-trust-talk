resource "local_file" "example_one_configmap" {
  filename = "${path.module}/../s3-consumer/config/configmap.yaml"
  content  = data.template_file.example_one_configmap.rendered
}

data "template_file" "example_one_configmap" {
  template = file("${path.module}/templates/example-one-config.yaml")
  vars = {
    audience = var.audience
    aws_region         = var.aws_region
    aws_role           = aws_iam_role.federated.arn
    s3_bucket          = aws_s3_bucket.target.bucket
    s3_object_key      = "test.txt"
  }
}