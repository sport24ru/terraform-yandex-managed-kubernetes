## 2.2.1 (August 17, 2022)

BUG FIXES:

* Fixed value of instance_template.container_runtime attribute of node group.

## 2.2.0 (June 1, 2022)

ENHANCEMENTS:

* Added attributes of cluster
  * cluster_ipv6_range
  * master_security_group_ids

* Added attributes of node group 
  * gpus
  * placement_group_id
  * container_runtime_type
  * network_acceleration_type
  * max_expansion
  * max_unavailable

NOTES:

* Required provider yandex >= 0.70
* Avoided usage of deprecated attribute
  `yandex_kubernetes_node_group.instance_template.nat` (fixed #3) 

## 2.1.0 (August 25, 2021)

ENHANCEMENTS:

* Added attribute `security_group_ids` of node group.

NOTES:

* Avoided warning about deprecated subnet definition (fixed #2).
* Required provider yandex >= 0.52