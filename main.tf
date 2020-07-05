locals {
  master_regions = length(var.master_locations) > 1 ? [{
    region    = var.master_region
    locations = var.master_locations
  }] : []

  master_locations = length(var.master_locations) > 1 ? [] : var.master_locations

  service_account_name = var.service_account_id == null ? var.service_account_name : null

  common_ssh_keys_metadata = length(var.node_groups_default_ssh_keys) > 0 ? {
    ssh-keys = join("\n", flatten([
      for username, ssh_keys in var.node_groups_default_ssh_keys : [
        for ssh_key in ssh_keys
        : "${username}:${ssh_key}"
      ]
    ]))
  } : {}

  node_groups_default_locations = coalesce(var.node_groups_default_locations, var.master_locations)
}

resource "yandex_iam_service_account" "service_account" {
  count = local.service_account_name == null ? 0 : 1

  name = var.service_account_name
}

locals {
  service_account_id = try(yandex_iam_service_account.service_account[0].id, var.service_account_id)
}

resource "yandex_resourcemanager_folder_iam_binding" "service_account" {
  count = local.service_account_name == null ? 0 : 1

  folder_id = var.folder_id
  members   = ["serviceAccount:${local.service_account_id}"]
  role      = "editor"
}

locals {
  node_service_account_name = var.node_service_account_id == null ? var.node_service_account_name : null

  node_service_account_exists = (local.node_service_account_name == null) || (var.service_account_name == var.node_service_account_name)
}

resource "yandex_iam_service_account" "node_service_account" {
  count = local.node_service_account_exists ? 0 : 1

  name = local.node_service_account_name
}

locals {
  node_service_account_id = try(yandex_iam_service_account.node_service_account[0].id, local.node_service_account_exists ? coalesce(var.node_service_account_id, local.service_account_id) : null)
}

resource "yandex_resourcemanager_folder_iam_binding" "node_service_account" {
  count = (local.node_service_account_name == null) || (var.service_account_name == var.node_service_account_name) ? 0 : 1

  folder_id = var.folder_id
  members   = ["serviceAccount:${local.node_service_account_id}"]
  role      = "container-registry.images.puller"
}

resource "yandex_kubernetes_cluster" "cluster" {
  name                    = var.name
  description             = var.description
  folder_id               = var.folder_id
  network_id              = var.network_id
  cluster_ipv4_range      = var.cluster_ipv4_range
  service_ipv4_range      = var.service_ipv4_range
  service_account_id      = local.service_account_id
  node_service_account_id = local.node_service_account_id
  release_channel         = var.release_channel

  labels = var.labels

  master {
    version   = var.master_version
    public_ip = var.master_public_ip

    dynamic "zonal" {
      for_each = local.master_locations

      content {
        zone      = zonal.value["zone"]
        subnet_id = zonal.value["subnet_id"]
      }
    }

    dynamic "regional" {
      for_each = local.master_regions

      content {
        region = regional.value["region"]

        dynamic "location" {
          for_each = regional.value["locations"]

          content {
            zone      = location.value["zone"]
            subnet_id = location.value["subnet_id"]
          }
        }
      }
    }
  }

  network_policy_provider = var.network_policy_provider

  dynamic "kms_provider" {
    for_each = var.kms_provider_key_id == null ? [] : [var.kms_provider_key_id]

    content {
      key_id = kms_provider.value
    }
  }

  // to keep permissions of service account on destroy
  // until cluster will be destroyed
  depends_on = [yandex_resourcemanager_folder_iam_binding.service_account]
}

resource "yandex_kubernetes_node_group" "node_groups" {
  for_each = var.node_groups

  cluster_id  = yandex_kubernetes_cluster.cluster.id
  name        = each.key
  description = lookup(each.value, "description", null)
  labels      = lookup(each.value, "labels", null)
  version     = lookup(each.value, "version", var.master_version)

  node_labels            = lookup(each.value, "node_labels", null)
  node_taints            = lookup(each.value, "node_taints", null)
  allowed_unsafe_sysctls = lookup(each.value, "allowed_unsafe_sysctls", null)

  instance_template {
    platform_id = lookup(each.value, "platform_id", null)
    nat         = lookup(each.value, "nat", null)
    metadata    = merge(local.common_ssh_keys_metadata, lookup(each.value, "metadata", {}))

    resources {
      cores         = lookup(each.value, "cores", 2)
      core_fraction = lookup(each.value, "core_fraction", 100)
      memory        = lookup(each.value, "memory", 2)
    }

    boot_disk {
      type = lookup(each.value, "boot_disk_type", "network-hdd")
      size = lookup(each.value, "boot_disk_size", 64)
    }

    scheduling_policy {
      preemptible = lookup(each.value, "preemptible", false)
    }
  }

  scale_policy {
    dynamic "fixed_scale" {
      for_each = flatten([lookup(each.value, "fixed_scale", can(each.value["auto_scale"]) ? [] : [{ size = 1 }])])

      content {
        size = fixed_scale.value.size
      }
    }

    dynamic "auto_scale" {
      for_each = flatten([lookup(each.value, "auto_scale", [])])

      content {
        min     = auto_scale.value.min
        max     = auto_scale.value.max
        initial = auto_scale.value.initial
      }
    }
  }

  allocation_policy {
    dynamic "location" {
      for_each = lookup(var.node_groups_locations, each.key, local.node_groups_default_locations)

      content {
        zone      = location.value.zone
        subnet_id = location.value.subnet_id
      }
    }
  }
}
