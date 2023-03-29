resource "local_file" "spire_server_config" {
  filename = "${path.module}/../config/spire-server-config.yaml"
  content  = data.template_file.spire_server_config.rendered
}

data "template_file" "spire_server_config" {
  template = file("${path.module}/templates/spire-server-config.yaml")
  vars = {
    spire_trust_domain = var.spire_trust_domain
    spire_issuer = local.spire_issuer
  }
}

resource "local_file" "spire_agent_config" {
  filename = "${path.module}/../config/spire-agent-config.yaml"
  content  = data.template_file.spire_agent_config.rendered
}

data "template_file" "spire_agent_config" {
  template = file("${path.module}/templates/spire-agent-config.yaml")
  vars = {
    spire_trust_domain = var.spire_trust_domain
  }
}

resource "local_file" "spire_controller_manager_config" {
  filename = "${path.module}/../config/spire-controller-manager-config.yaml"
  content  = data.template_file.spire_controller_manager_config.rendered
}

data "template_file" "spire_controller_manager_config" {
  template = file("${path.module}/templates/spire-controller-manager-config.yaml")
  vars = {
    spire_trust_domain = var.spire_trust_domain
  }
}

resource "local_file" "spire_cluster_spiffeid" {
  filename = "${path.module}/../config/spire-cluster-spiffeid.yaml"
  content  = data.template_file.spire_cluster_spiffeid.rendered
}

data "template_file" "spire_cluster_spiffeid" {
  template = file("${path.module}/templates/cluster-spiffeid.yaml")
  vars = {
    spire_trust_domain = var.spire_trust_domain
  }
}

resource "local_file" "jwks_retriever" {
  filename = "${path.module}/../config/jwks-retriever.yaml"
  content  = data.template_file.jwks_retriever.rendered
}

data "template_file" "jwks_retriever" {
  template = file("${path.module}/templates/jwks-retriever.yaml")
  vars = {
    spire_trust_domain = var.spire_trust_domain
  }
}