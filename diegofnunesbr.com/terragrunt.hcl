include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../modules/cloudflare/zone"
}

locals {
  zone_name = basename(get_terragrunt_dir())
  records   = yamldecode(file("${get_terragrunt_dir()}/records.yaml"))
}

inputs = {
  zone_name = local.zone_name
  records   = local.records
}
