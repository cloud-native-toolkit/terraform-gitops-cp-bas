module "gitops_module" {
  source = "./module"

  gitops_config = module.gitops.gitops_config
  git_credentials = module.gitops.git_credentials
  server_name = module.gitops.server_name
  namespace = module.gitops_namespace.name
  kubeseal_cert = module.gitops.sealed_secrets_cert
  default_storage_class = "ibmc-vpc-block-10iops-tier"
  db_archive_storage_class="portworx-db2-rwx-sc"
  postgres_storage_class="ibmc-vpc-block-10iops-tier"
  zookeeper_storage_class="ibmc-vpc-block-10iops-tier"
  kafka_storage_class="ibmc-vpc-block-10iops-tier"

  grafanapassword = "grafanapassword"
  dbpassword = "dbpassword"
}
