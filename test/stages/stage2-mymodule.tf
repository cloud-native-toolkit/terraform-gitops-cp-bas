module "gitops_module" {
  source = "./module"

  gitops_config = module.gitops.gitops_config
  git_credentials = module.gitops.git_credentials
  server_name = module.gitops.server_name
  namespace = module.gitops_namespace.name
  kubeseal_cert = module.gitops.sealed_secrets_cert
  db_archive_storage_class = module.sc_manager.rwx_storage_class
  default_storage_class = module.sc_manager.block_storage_class
  postgres_storage_class = module.sc_manager.block_storage_class
  zookeeper_storage_class = module.sc_manager.block_storage_class
  kafka_storage_class = module.sc_manager.block_storage_class

  grafanapassword = "grafanapassword"
  dbpassword = "dbpassword"
}
