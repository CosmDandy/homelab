terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1.0"
    }
  }
}

resource "null_resource" "install_consul" {
  provisioner "local-exec" {
    command = "${path.module}/../scripts/install/hashicorp_component.sh consul ${path.module}/../configs/core/consul/config.json"
  }
}

resource "null_resource" "install_vault" {
  depends_on = [null_resource.install_consul]

  provisioner "local-exec" {
    command = "${path.module}/../scripts/install/hashicorp_component.sh vault ${path.module}/../configs/core/vault/config.hcl"
  }
}

resource "null_resource" "install_docker" {
  provisioner "local-exec" {
    command = "${path.module}/../scripts/install/docker.sh"
  }
}

resource "null_resource" "install_nomad" {
  depends_on = [null_resource.install_docker, null_resource.install_vault]

  provisioner "local-exec" {
    command = "${path.module}/../scripts/install/hashicorp_component.sh nomad ${path.module}/../configs/core/nomad/config.hcl"
  }
}

resource "null_resource" "install_nomad_pack" {
  depends_on = [null_resource.install_nomad]

  provisioner "local-exec" {
    command = "${path.module}/../scripts/install/hashicorp_component.sh nomad_pack ${path.module}/../configs/core/nomad/config.hcl"
  }
}
