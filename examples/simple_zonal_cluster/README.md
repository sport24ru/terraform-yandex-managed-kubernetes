Simple zonal cluster
--------------------

This example illustrates how to create zonal cluster with a nodes placed in the same zone. In addition will be created
network and service account for managing node group. 

To provision this example configure provider by the environment variables, i.e.

```
export YC_CLOUD_ID=`yc config get cloud-id`
export YC_FOLDER_ID=`yc config get folder-id`
export YC_TOKEN=`yc config get token`
export YC_ZONE=`yc config get compute-default-zone`
```

then run from within this directory

* `terraform init` to get the plugins
* `terraform plan` to see the infrastructure plan
* `terraform apply` to apply the infrastructure build
* `terraform destroy` to destroy the built infrastructure
