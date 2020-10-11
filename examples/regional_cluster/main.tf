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

data "yandex_client_config" "client" {}

module "kubernetes" {
  source = "sport24ru/managed-kubernetes/yandex"

  name       = "regional-cluster"
  folder_id  = data.yandex_client_config.client.folder_id
  network_id = yandex_vpc_network.kubernetes.id

  master_region = "ru-central1"
  master_locations = [for subnet in yandex_vpc_subnet.kubernetes : {
    subnet_id = subnet.id
    zone      = subnet.zone
  }]

  service_account_name = "k8s-manager"

  node_groups = {
    default = {
      fixed_scale = {
        size = 3
      }
    }
  }
}
