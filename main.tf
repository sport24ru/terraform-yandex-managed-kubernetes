locals {
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

  folder_id = var.folder_id

  name = var.service_account_name
}

locals {
  service_account_id = try(yandex_iam_service_account.service_account[0].id, var.service_account_id)
}

resource "yandex_resourcemanager_folder_iam_member" "service_account" {
  count = local.service_account_name == null ? 0 : 1

  folder_id = var.folder_id

  role   = "editor"
  member = "serviceAccount:${local.service_account_id}"
}

locals {
  node_service_account_name = var.node_service_account_id == null ? var.node_service_account_name : null

  node_service_account_exists = local.node_service_account_name == null || var.service_account_name == var.node_service_account_name
}

resource "yandex_iam_service_account" "node_service_account" {
  count = local.node_service_account_exists ? 0 : 1

  folder_id = var.folder_id

  name = local.node_service_account_name
}

locals {
  node_service_account_id = try(yandex_iam_service_account.node_service_account[0].id, local.node_service_account_exists ? coalesce(var.node_service_account_id, local.service_account_id) : null)
}

resource "yandex_resourcemanager_folder_iam_member" "node_service_account" {
  count = (local.node_service_account_name == null) || (var.service_account_name == var.node_service_account_name) ? 0 : 1

  folder_id = var.folder_id

  role   = "container-registry.images.puller"
  member = "serviceAccount:${local.node_service_account_id}"
}

resource "yandex_kubernetes_cluster" "cluster" {
  name                     = var.name
  description              = var.description
  folder_id                = var.folder_id
  labels                   = var.labels
  network_id               = var.network_id
  cluster_ipv4_range       = var.cluster_ipv4_range
  cluster_ipv6_range       = var.cluster_ipv6_range
  node_ipv4_cidr_mask_size = var.node_ipv4_cidr_mask_size
  service_ipv4_range       = var.service_ipv4_range
  service_account_id       = local.service_account_id
  node_service_account_id  = local.node_service_account_id
  release_channel          = var.release_channel
  network_policy_provider  = var.network_policy_provider

  dynamic "kms_provider" {
    for_each = var.kms_provider_key_id == null ? [] : [var.kms_provider_key_id]

    content {
      key_id = kms_provider.value
    }
  }

  master {
    version            = var.master_version
    public_ip          = var.master_public_ip
    security_group_ids = var.master_security_group_ids

    dynamic "master_location" {
      for_each = var.master_locations

      content {
        zone      = master_location.value["zone"]
        subnet_id = master_location.value["subnet_id"]
      }
    }

    maintenance_policy {
      auto_upgrade = var.master_auto_upgrade

      dynamic "maintenance_window" {
        for_each = var.master_maintenance_windows

        content {
          day        = lookup(maintenance_window.value, "day", null)
          start_time = maintenance_window.value["start_time"]
          duration   = maintenance_window.value["duration"]
        }
      }
    }

    master_logging {
      enabled                    = var.master_logging.enabled
      folder_id                  = var.folder_id
      kube_apiserver_enabled     = var.master_logging.enabled_kube_apiserver
      cluster_autoscaler_enabled = var.master_logging.enabled_autoscaler
      events_enabled             = var.master_logging.enabled_events
    }
  }

  // to keep permissions of service account on destroy
  // until cluster will be destroyed
  depends_on = [yandex_resourcemanager_folder_iam_member.service_account]
}

resource "yandex_kubernetes_node_group" "node_groups" {
  for_each = var.node_groups

  cluster_id  = yandex_kubernetes_cluster.cluster.id
  name        = each.key
  description = lookup(each.value, "description", null)
  labels      = lookup(each.value, "labels", null)
  version     = lookup(each.value, "version", var.master_version)

  instance_template {
    platform_id = lookup(each.value, "platform_id", null)
    metadata    = merge(local.common_ssh_keys_metadata, lookup(each.value, "metadata", {}))

    resources {
      cores         = lookup(each.value, "cores", 2)
      core_fraction = lookup(each.value, "core_fraction", 100)
      memory        = lookup(each.value, "memory", 2)
      gpus          = lookup(each.value, "gpus", null)
    }

    boot_disk {
      type = lookup(each.value, "boot_disk_type", "network-hdd")
      size = lookup(each.value, "boot_disk_size", 64)
    }

    scheduling_policy {
      preemptible = lookup(each.value, "preemptible", false)
    }

    dynamic "placement_policy" {
      for_each = compact([lookup(each.value, "placement_group_id", null)])

      content {
        placement_group_id = placement_policy.value
      }
    }

    network_interface {
      subnet_ids         = [for location in lookup(var.node_groups_locations, each.key, local.node_groups_default_locations) : location.subnet_id]
      nat                = lookup(each.value, "nat", null)
      security_group_ids = lookup(each.value, "security_group_ids", null)
    }

    network_acceleration_type = lookup(each.value, "network_acceleration_type", null)

    dynamic "container_runtime" {
      for_each = compact([lookup(each.value, "container_runtime_type", null)])

      content {
        type = container_runtime.value
      }
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
        zone = location.value.zone
      }
    }
  }

  maintenance_policy {
    auto_repair  = lookup(each.value, "auto_repair", true)
    auto_upgrade = lookup(each.value, "auto_upgrade", true)

    dynamic "maintenance_window" {
      for_each = lookup(each.value, "maintenance_windows", [])

      content {
        day        = lookup(maintenance_window.value, "day", null)
        start_time = maintenance_window.value["start_time"]
        duration   = maintenance_window.value["duration"]
      }
    }
  }

  node_labels            = lookup(each.value, "node_labels", null)
  node_taints            = lookup(each.value, "node_taints", null)
  allowed_unsafe_sysctls = lookup(each.value, "allowed_unsafe_sysctls", null)

  dynamic "deploy_policy" {
    for_each = anytrue([can(each.value["max_expansion"]), can(each.value["max_unavailable"])]) ? [{
      max_expansion   = lookup(each.value, "max_expansion", null)
      max_unavailable = lookup(each.value, "max_unavailable", null)
    }] : []

    content {
      max_expansion   = each.value["max_expansion"]
      max_unavailable = each.value["max_unavailable"]
    }
  }
}
