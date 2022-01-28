
resource null_resource write_outputs {
  provisioner "local-exec" {
    command = "echo \"$${OUTPUT}\" > eventstreams-output.json"

    environment = {
      OUTPUT = jsonencode({
        name   = module.eventstreams_module.name
        branch = module.eventstreams_module.branch
        //  namespace   = module.eventstreams_module.namespace
        server_name = module.eventstreams_module.server_name
        layer       = module.eventstreams_module.layer
        layer_dir   = module.eventstreams_module.layer == "infrastructure" ? "1-infrastructure" : (module.eventstreams_module.layer == "services" ? "2-services" : "3-applications")
        type        = module.eventstreams_module.type
      })
    }
  }
}
