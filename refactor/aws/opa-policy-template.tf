resource "local_file" "opa_policy" {
  filename = "${path.module}/../opa/example.rego"
  content  = data.template_file.opa_policy.rendered
}

data "template_file" "opa_policy" {
  template = file("${path.module}/templates/example.rego")
  vars = {
    spire_trust_domain = local.spire_trust_domain
  }
}