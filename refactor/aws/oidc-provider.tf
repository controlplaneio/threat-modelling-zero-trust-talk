resource "aws_iam_openid_connect_provider" "spire" {
  url = "https://${local.spire_trust_domain}"
  thumbprint_list = [
    var.thumbprint,
  ]
  client_id_list = [
    var.audience,
  ]
}

resource "local_file" "oidc_discovery_document" {
  filename = "${path.module}/../oidc/openid-configuration"
  content  = data.template_file.oidc_discovery_document.rendered
}

data "template_file" "oidc_discovery_document" {
  template = file("${path.module}/templates/oidc-discovery-document.json")
  vars = {
    spire_trust_domain = local.spire_trust_domain
  }
}