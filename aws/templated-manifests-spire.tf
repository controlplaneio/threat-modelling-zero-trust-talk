resource "local_file" "spire_server" {
  filename = "${path.module}/../spire/config/spire-server.yaml"
  content  = data.template_file.spire_server.rendered
}

data "template_file" "spire_server" {
  template = file("${path.module}/templates/spire-server.yaml")
  vars = {
    spire_trust_domain = local.spire_trust_domain
  }
}

resource "local_file" "spire_agent" {
  filename = "${path.module}/../spire/config/spire-agent.yaml"
  content  = data.template_file.spire_agent.rendered
}

data "template_file" "spire_agent" {
  template = file("${path.module}/templates/spire-agent.yaml")
  vars = {
    spire_trust_domain = local.spire_trust_domain
  }
}

resource "local_file" "spire_controller_manager_config" {
  filename = "${path.module}/../spire/config/spire-controller-manager-config.yaml"
  content  = data.template_file.spire_controller_manager_config.rendered
}

data "template_file" "spire_controller_manager_config" {
  template = file("${path.module}/templates/spire-controller-manager-config.yaml")
  vars = {
    spire_trust_domain = local.spire_trust_domain
  }
}

resource "local_file" "spire_cluster_spiffeid" {
  filename = "${path.module}/../spire/config/spire-cluster-spiffeid.yaml"
  content  = data.template_file.spire_cluster_spiffeid.rendered
}

data "template_file" "spire_cluster_spiffeid" {
  template = file("${path.module}/templates/cluster-spiffeid.yaml")
  vars = {
    spire_trust_domain = local.spire_trust_domain
  }
}
