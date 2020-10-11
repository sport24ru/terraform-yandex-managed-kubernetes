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

  name       = "ssh-keys"
  folder_id  = data.yandex_client_config.client.folder_id
  network_id = yandex_vpc_subnet.kubernetes.network_id

  master_locations = [{
    subnet_id = yandex_vpc_subnet.kubernetes.id
    zone      = yandex_vpc_subnet.kubernetes.zone
  }]

  service_account_name = "k8s-manager"

  node_groups = {
    default = {
      fixed_scale = {
        size = 1
      }
    }
  }

  node_groups_default_ssh_keys = {
    admin = [
      "ssh-rsa AA...Hp admin1",
      "ssh-rsa AA...Gz admin2",
    ],
    user = [
      "ssh-rsa AA..Rt user",
    ],
  }
}
