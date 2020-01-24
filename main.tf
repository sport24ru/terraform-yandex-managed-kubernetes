locals {
  regions = length(var.master_zones) > 1 ? [{
    region    = var.master_region
    locations = var.master_zones
  }] : []

  zones = length(var.master_zones) > 1 ? [] : var.master_zones

  node_service_account_count = (var.service_account_name == null) || (var.service_account_name == var.node_service_account_name) ? 0 : 1
}

resource "yandex_iam_service_account" "service_account" {
  name = var.service_account_name
}

resource "yandex_resourcemanager_folder_iam_binding" "service_account" {
  folder_id = var.folder_id
  members   = ["serviceAccount:${yandex_iam_service_account.service_account.id}"]
  role      = "editor"
}

resource "yandex_iam_service_account" "node_service_account" {
  count = local.node_service_account_count

  name = var.service_account_name
}

resource "yandex_resourcemanager_folder_iam_binding" "node_service_account" {
  count = local.node_service_account_count

  folder_id = var.folder_id
  members   = ["serviceAccount:${yandex_iam_service_account.node_service_account[0].id}"]
  role      = "container-registry.images.puller"
}

locals {
  node_service_account_id = local.node_service_account_count > 0 ? yandex_iam_service_account.node_service_account[0].id : yandex_iam_service_account.service_account.id
}

resource "yandex_kubernetes_cluster" "default" {
  name                    = var.name
  description             = var.description
  folder_id               = var.folder_id
  network_id              = var.network_id
  cluster_ipv4_range      = var.cluster_ipv4_range
  service_ipv4_range      = var.service_ipv4_range
  service_account_id      = yandex_iam_service_account.service_account.id
  node_service_account_id = local.node_service_account_id
  release_channel         = var.release_channel

  labels = var.labels

  master {
    version   = var.master_version
    public_ip = var.master_public_ip

    dynamic "zonal" {
      for_each = local.zones

      content {
        zone      = zonal.value["zone"]
        subnet_id = zonal.value["id"]
      }
    }

    dynamic "regional" {
      for_each = local.regions

      content {
        region = regional.value["region"]

        dynamic "location" {
          for_each = regional.value["locations"]

          content {
            zone      = location.value["zone"]
            subnet_id = location.value["id"]
          }
        }
      }
    }
  }
}

resource "yandex_kubernetes_node_group" "default" {
  count = length(var.node_groups)

  cluster_id  = yandex_kubernetes_cluster.default.id
  name        = lookup(var.node_groups[count.index], "name", null)
  description = lookup(var.node_groups[count.index], "description", null)
  labels      = lookup(var.node_groups[count.index], "labels", {})
  version     = lookup(var.node_groups[count.index], "version", var.master_version)

  instance_template {
    platform_id = lookup(var.node_groups[count.index], "platform_id", null)
    nat         = lookup(var.node_groups[count.index], "nat", null)
    metadata    = lookup(var.node_groups[count.index], "metadata", null)

    resources {
      cores         = lookup(var.node_groups[count.index], "cores", 2)
      core_fraction = lookup(var.node_groups[count.index], "core_fraction", 100)
      memory        = lookup(var.node_groups[count.index], "memory", 2)
    }

    boot_disk {
      type = lookup(var.node_groups[count.index], "boot_disk_type", "network-ssd")
      size = lookup(var.node_groups[count.index], "boot_disk_size", 64)
    }

    scheduling_policy {
      preemptible = lookup(var.node_groups[count.index], "preemptible", false)
    }
  }

  scale_policy {
    fixed_scale {
      size = lookup(var.node_groups[count.index], "size", 1)
    }
  }

  allocation_policy {
    dynamic "location" {
      for_each = lookup(var.node_groups[count.index], "zones", var.master_zones)

      content {
        zone      = location.value.zone
        subnet_id = location.value.id
      }
    }
  }
}