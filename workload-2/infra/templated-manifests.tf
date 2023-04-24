resource "local_file" "destination_rule" {
  filename = "${path.module}/../config/destination-rule.yaml"
  content  = data.template_file.destination_rule.rendered
}

data "template_file" "destination_rule" {
  template = file("${path.module}/templates/destination-rule.yaml")
  vars = {
    spire_trust_domain = var.spire_trust_domain
  }
}