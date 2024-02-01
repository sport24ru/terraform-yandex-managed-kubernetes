variable "name" {
  description = "Name of a specific Kubernetes cluster."

  type = string

  default = null
}

variable "description" {
  description = "A description of the Kubernetes cluster."

  type = string

  default = null
}

variable "folder_id" {
  description = "The ID of the folder that the Kubernetes cluster belongs to."

  type = string
}

variable "labels" {
  description = "A set of key/value label pairs to assign to the Kubernetes cluster."

  type = map(string)

  default = {}
}

variable "network_id" {
  description = "The ID of the cluster network."

  type = string
}

variable "cluster_ipv4_range" {
  description = <<-EOF
  CIDR block. IP range for allocating pod addresses. It should not overlap with
  any subnet in the network the Kubernetes cluster located in. Static routes will
  be set up for this CIDR blocks in node subnets.
  EOF

  type = string

  default = null
}

variable "cluster_ipv6_range" {
  description = "Identical to cluster_ipv4_range but for IPv6 protocol."

  type = string

  default = null
}

variable "node_ipv4_cidr_mask_size" {
  description = <<-EOF
  Size of the masks that are assigned to each node in the cluster. Effectively
  limits maximum number of pods for each node.
  EOF

  type = number

  default = null
}

variable "service_ipv4_range" {
  description = <<-EOF
  CIDR block. IP range Kubernetes service Kubernetes cluster IP addresses
  will be allocated from. It should not overlap with any subnet in the network
  the Kubernetes cluster located in.
  EOF

  type = string

  default = null
}

variable "service_account_id" {
  description = <<-EOF
  ID of existing service account to be used for provisioning Compute Cloud
  and VPC resources for Kubernetes cluster. Selected service account should have
  edit role on the folder where the Kubernetes cluster will be located and on the
  folder where selected network resides.
  EOF

  type = string

  default = null
}

variable "service_account_name" {
  description = <<-EOF
  Name of service account to create to be used for provisioning Compute Cloud
  and VPC resources for Kubernetes cluster.

  `service_account_name` is ignored if `service_account_id` is set.
  EOF

  type = string

  default = null
}

variable "node_service_account_id" {
  description = <<-EOF
  ID of service account to be used by the worker nodes of the Kubernetes
  cluster to access Container Registry or to push node logs and metrics.

  If omitted or equal to `service_account_id`, service account will be used
  as node service account.
  EOF

  type = string

  default = null
}

variable "node_service_account_name" {
  description = <<-EOF
  Name of service account to create to be used by the worker nodes of
  the Kubernetes cluster to access Container Registry or to push node logs
  and metrics.

  If omitted or equal to `service_account_name`, service account
  will be used as node service account.

  `node_service_account_name` is ignored if `node_service_account_id` is set.
  EOF

  type = string

  default = null
}

variable "release_channel" {
  description = "Cluster release channel."

  type = string

  default = "STABLE"
}

variable "network_policy_provider" {
  description = "Network policy provider for the cluster. Possible values: CALICO."

  type = string

  default = null
}

variable "kms_provider_key_id" {
  description = "KMS key ID."

  default = null
}

variable "master_version" {
  description = "Version of Kubernetes that will be used for master."

  type = string

  default = null
}

variable "master_public_ip" {
  description = "Boolean flag. When true, Kubernetes master will have visible ipv4 address."

  type = bool

  default = true
}

variable "master_security_group_ids" {
  description = "List of security group IDs to which the Kubernetes cluster belongs."

  type = set(string)

  default = null
}

variable "master_region" {
  description = <<-EOF
  Name of region where cluster will be created. Required for regional cluster,
  not used for zonal cluster.
  EOF

  type = string

  default = null
}

variable "master_locations" {
  description = <<-EOF
  List of locations where cluster will be created. If list contains only one
  location, will be created zonal cluster, if more than one -- regional.
  EOF

  type = list(object({
    zone      = string
    subnet_id = string
  }))
}

variable "master_auto_upgrade" {
  description = <<-EOF
  Boolean flag that specifies if master can be upgraded automatically.
  EOF

  type = bool

  default = true
}

variable "master_maintenance_windows" {
  description = <<EOF
  List of structures that specifies maintenance windows,
  when auto update for master is allowed.

  Example:
  ```
  master_maintenance_windows = [
    {
      start_time = "23:00"
      duration   = "3h"
    }
  ]
  ```
  EOF

  type = list(map(string))

  default = []
}

variable "node_groups" {
  description = "Parameters of Kubernetes node groups."

  default = {}
}

variable "node_groups_default_ssh_keys" {
  description = <<-EOF
  Map containing SSH keys to install on all Kubernetes node servers by default.
  EOF

  type = map(list(string))

  default = {}
}

variable "node_groups_default_locations" {
  description = <<-EOF
  Default locations of Kubernetes node groups.

  If ommited, master_locations will be used.
  EOF

  type = list(object({
    subnet_id = string
    zone      = string
  }))

  default = null
}

variable "node_groups_locations" {
  description = <<-EOF
  Locations of Kubernetes node groups.

  Use it to override default locations of certain node groups.
  EOF

  type = map(list(object({
    subnet_id = string
    zone      = string
  })))

  default = {}
}

variable "master_logging" {
  description = "master_logging options"
  type        = map(any)
  default = {
    enabled                = false
    folder_id              = null
    enabled_kube_apiserver = false
    enabled_autoscaler     = false
    enabled_events         = false
  }
}
