resource "yandex_vpc_network" "kubernetes" {
  name = "kubernetes"
}

resource "yandex_vpc_subnet" "kubernetes" {
  name = "kubernetes"

  network_id     = yandex_vpc_network.kubernetes.id
  v4_cidr_blocks = ["10.0.0.0/16"]
}

data "yandex_client_config" "client" {}

module "kubernetes" {
  source = "sport24ru/managed-kubernetes/yandex"

  name       = "maintenance-policy"
  folder_id  = data.yandex_client_config.client.folder_id
  network_id = yandex_vpc_subnet.kubernetes.network_id

  master_locations = [{
    subnet_id = yandex_vpc_subnet.kubernetes.id
    zone      = yandex_vpc_subnet.kubernetes.zone
  }]

  master_auto_upgrade = true

  master_maintenance_windows = [
    {
      start_time = "01:00"
      duration   = "2h"
    },
  ]

  service_account_name = "k8s-manager"

  node_groups = {
    default = {
      fixed_scale = {
        size = 2
      }

      auto_upgrade = true

      maintenance_windows = [
        {
          day        = "monday"
          start_time = "7:00"
          duration   = "4h"
        },
        {
          day        = "wednesday"
          start_time = "23:00"
          duration   = "3h"
        },
      ]
    }
  }
}
