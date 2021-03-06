module "eventstreams_module" {
  source = "./module"

  gitops_config   = module.gitops.gitops_config
  git_credentials = module.gitops.git_credentials
  server_name     = module.gitops.server_name
  catalog         = module.cp_catalogs.catalog_ibmoperators
  channel         = module.cp4i-dependencies.eventstreams.channel
  //comment channel = "v2.5"
  //  kubeseal_cert   = module.gitops.sealed_secrets_cert
}
