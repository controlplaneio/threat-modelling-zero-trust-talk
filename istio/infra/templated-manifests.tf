resource "local_file" "istio_operator" {
  filename = "${path.module}/../istio-operator.yaml"
  content  = data.template_file.istio_operator.rendered
}

data "template_file" "istio_operator" {
  template = file("${path.module}/templates/istio-operator.yaml")
  vars = {
    spire_trust_domain = local.spire_trust_domain
  }
}

resource "local_file" "opa_injection" {
  filename = "${path.module}/../config/opa-injection.yaml"
  content  = data.template_file.opa_injection.rendered
}

data "template_file" "opa_injection" {
  template = file("${path.module}/templates/opa-injection.yaml")
  vars = {
    opa_policy_fetch_role_arn = aws_iam_role.opa.arn
  }
}

resource "local_file" "opa_istio_configmap" {
  filename = "${path.module}/../config/opa-istio-configmap.yaml"
  content  = data.template_file.opa_istio_configmap.rendered
}

data "template_file" "opa_istio_configmap" {
  template = file("${path.module}/templates/opa-istio-configmap.yaml")
  vars = {
    aws_region             = var.aws_region
    opa_policy_bucket_name = var.opa_policy_bucket_name
  }
}
