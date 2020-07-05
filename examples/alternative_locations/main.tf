resource "yandex_vpc_network" "kubernetes" {
  name = "kubernetes"
}

resource "yandex_vpc_subnet" "kubernetes" {
  for_each = {
    "a" = "10.10.0.0/16"
    "b" = "10.20.0.0/16"
    "c" = "10.30.0.0/16"
  }

  name       = "kubernetes-${each.key}"
  network_id = yandex_vpc_network.kubernetes.id

  zone           = "ru-central1-${each.key}"
  v4_cidr_blocks = [each.value]
}

locals {
  node_groups_default_locations = [
    for subnet in yandex_vpc_subnet.kubernetes : {
      subnet_id = subnet.id
      zone      = subnet.zone
    }
  ]
}

data "yandex_client_config" "client" {}

module "kubernetes" {
  source = "github.com/sport24ru/terraform-yandex-managed-kubernetes"

  name       = "alternative-locations"
  folder_id  = data.yandex_client_config.client.folder_id
  network_id = yandex_vpc_network.kubernetes.id

  master_locations = [{
    subnet_id = yandex_vpc_subnet.kubernetes["a"].id
    zone      = yandex_vpc_subnet.kubernetes["a"].zone
  }]

  service_account_name = "k8s-manager"

  node_groups_default_locations = local.node_groups_default_locations

  node_groups_locations = {
    special = [{
      subnet_id = yandex_vpc_subnet.kubernetes["b"].id
      zone      = yandex_vpc_subnet.kubernetes["b"].zone
    }]
  }

  node_groups = {
    main = {
      fixed_scale = {
        size = 3
      }
    }
    special = {
      fixed_scale = {
        size = 1
      }
    }
  }
}
