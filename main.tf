locals {
  operator_name = "bas-operator"
  name          = "bas"
  bin_dir       = module.setup_clis.bin_dir
  operator_chart_dir = "${path.module}/charts/bas-operator"
  operator_yaml_dir  = "${path.cwd}/.tmp/${local.name}/chart/${local.operator_name}"
  chart_dir          = "${path.module}/charts/bas"
  yaml_dir           = "${path.cwd}/.tmp/${local.name}/chart/${local.name}"
  secret_dir         = "${path.cwd}/.tmp/${local.name}/secrets"
  values_content = {
  }
  layer = "services"
  operator_type  = "operator"
  type  = "instance"
  application_branch = "main"
  namespace = var.namespace
  layer_config = var.gitops_config[local.layer]
}

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"
}

resource null_resource create_operator_yaml {
  triggers = {
    name      = local.operator_name
    chart_dir = local.operator_chart_dir
    yaml_dir  = local.operator_yaml_dir
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${self.triggers.name}' '${self.triggers.chart_dir}' '${self.triggers.yaml_dir}'"
  }
}

resource null_resource setup_operator_gitops {
  depends_on = [null_resource.create_operator_yaml]

  triggers = {
    name = local.operator_name
    namespace = var.namespace
    yaml_dir = local.operator_yaml_dir
    server_name = var.server_name
    layer = local.layer
    type = local.operator_type
    git_credentials = yamlencode(var.git_credentials)
    gitops_config   = yamlencode(var.gitops_config)
    bin_dir = local.bin_dir
  }

  provisioner "local-exec" {
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }

  provisioner "local-exec" {
    when = destroy
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --delete --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }
}

resource null_resource create_yaml {
  triggers = {
    name      = local.name
    chart_dir = local.chart_dir
    yaml_dir  = local.yaml_dir
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-yaml.sh '${self.triggers.name}' '${self.triggers.chart_dir}' '${self.triggers.yaml_dir}'"
  }
}

resource null_resource create_secrets_yaml {
  depends_on = [null_resource.create_yaml]

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-secrets.sh '${var.namespace}' '${local.secret_dir}'"

    environment = {
      DB_USER = var.dbuser
      DB_PASSWORD = var.dbpassword
      GRAFANA_USER = var.grafanauser
      GRAFANA_PASSWORD = var.grafanapasswod
    }
  }
}

module seal_secrets {
  depends_on = [null_resource.create_secrets_yaml]

  source = "github.com/cloud-native-toolkit/terraform-util-seal-secrets.git?ref=v1.0.0"

  source_dir    = local.secret_dir
  dest_dir      = local.yaml_dir
  kubeseal_cert = var.kubeseal_cert
  label         = local.name
}

resource null_resource setup_gitops {
  depends_on = [null_resource.create_yaml, null_resource.create_secrets_yaml, module.seal_secrets]

  triggers = {
    name = local.operator_name
    namespace = var.namespace
    yaml_dir = module.seal_secrets.dest_dir
    server_name = var.server_name
    layer = local.layer
    type = local.type
    git_credentials = yamlencode(var.git_credentials)
    gitops_config   = yamlencode(var.gitops_config)
    bin_dir = local.bin_dir
  }

  provisioner "local-exec" {
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }

  provisioner "local-exec" {
    when = destroy
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --delete --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}'"

    environment = {
      GIT_CREDENTIALS = nonsensitive(self.triggers.git_credentials)
      GITOPS_CONFIG   = self.triggers.gitops_config
    }
  }
}