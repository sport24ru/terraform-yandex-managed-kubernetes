output "external_v4_endpoint" {
  description = "An IPv4 external network address that is assigned to the master."

  value = yandex_kubernetes_cluster.cluster.master[0].external_v4_endpoint
}

output "cluster_ca_certificate" {
  description = <<-EOF
  PEM-encoded public certificate that is the root of trust for
  the Kubernetes cluster.
  EOF

  value = yandex_kubernetes_cluster.cluster.master[0].cluster_ca_certificate
}

output "cluster_id" {
  description = "ID of a new Kubernetes cluster."

  value = yandex_kubernetes_cluster.cluster.id
}

output "node_groups" {
  description = "Attributes of yandex_node_group resources created in cluster"

  value = yandex_kubernetes_node_group.node_groups
}

output "service_account_id" {
  description = <<-EOF
  ID of service account used for provisioning Compute Cloud and VPC resources
  for Kubernetes cluster
  EOF

  value = local.service_account_id
}

output "node_service_account_id" {
  description = <<-EOF
  ID of service account to be used by the worker nodes of the Kubernetes cluster
  to access Container Registry or to push node logs and metrics
  EOF

  value = local.node_service_account_id
}
