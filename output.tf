output "host" {
  value = yandex_kubernetes_cluster.default.master[0].external_v4_endpoint
}

output "cluster_ca_certificate" {
  value = yandex_kubernetes_cluster.default.master[0].cluster_ca_certificate
}

output "cluster_id" {
  value = yandex_kubernetes_cluster.default.id
}

// For now this output used only to inject dependency to helm module
output "node_group_ids" {
  value = yandex_kubernetes_node_group.default[*].id
}
