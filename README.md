# Terraform Yandex Managed Kubernetes Module

A terraform module to create a managed Kubernetes cluster on Yandex Cloud.
Module will manage

- service accounts for managing cluster resources,
- Kubernetes cluster itself,
- node groups in the cluster.

This module is meant for use with Terraform >= 0.13.

## Example Usage

```hcl-terraform
resource "yandex_vpc_network" "default" {
  name = "default"
}

resource "yandex_vpc_subnet" "a" {
  network_id = yandex_vpc_network.default.id

  name = "a"
  zone = "ru-central1-a"

  v4_cidr_blocks = ["10.1.0.0/16"]
}

module "kubernetes" {
  source = "sport24ru/managed-kubernetes/yandex"

  name             = "default"

  folder_id        = var.folder_id
  network_id       = yandex_vpc_network.default.id
  master_locations = [
    {
      subnet_id = yandex_vpc_subnet.a.id
      zone      = yandex_vpc_subnet.a.zone
    }
  ]

  service_account_name      = "k8s-manager"
  node_service_account_name = "k8s-node-manager"

  master_version  = var.kubernetes_version
  release_channel = var.kubernetes_release_channel

  node_groups = {
    "default" = {
      cores         = 4
      core_fraction = 100
      memory        = 8
      fixed_scale = {
        size = 3
      }
      boot_disk_type = "network-hdd"
      boot_disk_size = 64
    }
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster\_ipv4\_range | CIDR block. IP range for allocating pod addresses. It should not overlap with<br>any subnet in the network the Kubernetes cluster located in. Static routes will<br>be set up for this CIDR blocks in node subnets. | `string` | `null` | no |
| description | A description of the Kubernetes cluster. | `string` | `null` | no |
| folder\_id | The ID of the folder that the Kubernetes cluster belongs to. | `string` | n/a | yes |
| kms\_provider\_key\_id | KMS key ID. | `any` | `null` | no |
| labels | A set of key/value label pairs to assign to the Kubernetes cluster. | `map(string)` | `{}` | no |
| master\_auto\_upgrade | Boolean flag that specifies if master can be upgraded automatically. | `bool` | `true` | no |
| master\_locations | List of locations where cluster will be created. If list contains only one<br>location, will be created zonal cluster, if more than one -- regional. | <pre>list(object({<br>  zone      = string<br>  subnet_id = string<br>}))</pre> | n/a | yes |
| master\_maintenance\_windows | List of structures that specifies maintenance windows, when auto update for master is allowed. | `list(map(string))` | `[]` | no |
| master\_public\_ip | Boolean flag. When true, Kubernetes master will have visible ipv4 address. | `bool` | `true` | no |
| master\_region | Name of region where cluster will be created. Required for regional cluster,<br>not used for zonal cluster. | `string` | `null` | no |
| master\_version | Version of Kubernetes that will be used for master. | `string` | `null` | no |
| name | Name of a specific Kubernetes cluster. | `string` | `null` | no |
| network\_id | The ID of the cluster network. | `string` | n/a | yes |
| network\_policy\_provider | Network policy provider for the cluster. Possible values: CALICO. | `string` | `null` | no |
| node\_groups | Parameters of Kubernetes node groups. | `map` | `{}` | no |
| node\_groups\_default\_locations | Default locations of Kubernetes node groups.<br><br>If ommited, master\_locations will be used. | <pre>list(object({<br>  subnet_id = string<br>  zone      = string<br>}))</pre> | `null` | no |
| node\_groups\_default\_ssh\_keys | Map containing SSH keys to install on all Kubernetes node servers by default. | `map(list(string))` | `{}` | no |
| node\_groups\_locations | Locations of Kubernetes node groups.<br><br>Use it to override default locations of certain node groups. | <pre>map(list(object({<br>  subnet_id = string<br>  zone      = string<br>})))</pre> | `{}` | no |
| node\_ipv4\_cidr\_mask\_size | Size of the masks that are assigned to each node in the cluster. Effectively<br>limits maximum number of pods for each node. | `number` | `null` | no |
| node\_service\_account\_id | ID of service account to be used by the worker nodes of the Kubernetes<br>cluster to access Container Registry or to push node logs and metrics.<br><br>If omitted or equal to `service_account_id`, service account will be used<br>as node service account. | `string` | `null` | no |
| node\_service\_account\_name | Name of service account to create to be used by the worker nodes of<br>the Kubernetes cluster to access Container Registry or to push node logs<br>and metrics.<br><br>If omitted or equal to `service_account_name`, service account<br>will be used as node service account.<br><br>`node_service_account_name` is ignored if `node_service_account_id` is set. | `string` | `null` | no |
| release\_channel | Cluster release channel. | `string` | `"STABLE"` | no |
| service\_account\_id | ID of existing service account to be used for provisioning Compute Cloud<br>and VPC resources for Kubernetes cluster. Selected service account should have<br>edit role on the folder where the Kubernetes cluster will be located and on the<br>folder where selected network resides. | `string` | `null` | no |
| service\_account\_name | Name of service account to create to be used for provisioning Compute Cloud<br>and VPC resources for Kubernetes cluster.<br><br>`service_account_name` is ignored if `service_account_id` is set. | `string` | `null` | no |
| service\_ipv4\_range | CIDR block. IP range Kubernetes service Kubernetes cluster IP addresses<br>will be allocated from. It should not overlap with any subnet in the network<br>the Kubernetes cluster located in. | `string` | `null` | no |

### node_groups attributes

`node_groups` is a map where each key is a name of node group and a corresponding
value is a map of node group attributes. 

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| description | A description of the Kubernetes node group | `string` | | no | 
| labels | A set of key/value label pairs assigned to the Kubernetes node group | `map(string)` | no |
| version | Version of Kubernetes that will be used for Kubernetes node group | `string` | Value of `master_version` variable | no |
| node_labels | A set of key/value label pairs, that are assigned to all the nodes of this Kubernetes node group | `map(string)` | | no |
| node_taints | A list of Kubernetes taints, that are applied to all the nodes of this Kubernetes node group | `list(string)` | | no |
| allowed_unsafe_sysctls | A list of allowed unsafe sysctl parameters for this node group | `list(string)` | | no |
| platform_id | The ID of the hardware platform configuration for the node group compute instances | `string` | | no |
| nat | Boolean flag, enables NAT for node group compute instances | `bool` | | no |
| metadata | The set of metadata key:value pairs assigned to this instance template. This includes custom metadata and predefined keys | `map(string)` | | no |
| cores | Number of CPU cores allocated to the instance | `number` | 2 | no |
| core_fraction | Baseline core performance as a percent | `number` | 100 | no |
| memory | The memory size allocated to the instance | `number` | 2 | no |
| boot_disk_type | The boot disk type | `string` | "network-hdd" | no |
| boot_disk_size | The size of the boot disk in GB. Allowed minimal size: 64 GB | `number` | 64 | no |  
| preemptible | Specifies if the instance is preemptible | `bool` | false | no |
| fixed_scale | Scale policy for a fixed scale node group | <pre>object({<br>  size = number<br>})</pre> | | One of `fixed_scale` or `auto_scale` must be defined |
| auto_scale | Scale policy for an autoscaled node group | <pre>object({<br>  min = number<br>  max = number<br>  initial = number<br>})</pre> | | One of `fixed_scale` or `auto_scale` must be defined |
| auto_upgrade | Boolean flag that specifies if node group can be upgraded automatically. | `bool` | `true` | no |
| auto_repair | Boolean flag that specifies if node group can be repaired automatically. | `bool` | `true` | no |
| maintenance_windows | List of day intervals, when maintenance is allowed for this node group. | `list(map(string))` | [] | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster\_ca\_certificate | PEM-encoded public certificate that is the root of trust for<br>the Kubernetes cluster. |
| cluster\_id | ID of a new Kubernetes cluster. |
| external\_v4\_endpoint | An IPv4 external network address that is assigned to the master. |
| node\_groups | Attributes of yandex\_node\_group resources created in cluster |
| node\_service\_account\_id | ID of service account to be used by the worker nodes of the Kubernetes cluster<br>to access Container Registry or to push node logs and metrics |
| service\_account\_id | ID of service account used for provisioning Compute Cloud and VPC resources<br>for Kubernetes cluster |

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.0 |
| yandex | >= 0.44.0 |

## Providers

| Name | Version |
|------|---------|
| yandex | >= 0.44.0 |
