locals {
  operator_name = "bas-operator"
  name          = "bas-instance"
  bin_dir       = module.setup_clis.bin_dir
  operator_chart_dir = "${path.module}/charts/bas-operator"
  operator_yaml_dir  = "${path.cwd}/.tmp/${local.name}/chart/${local.operator_name}"
  chart_dir          = "${path.module}/charts/bas-instance"
  yaml_dir           = "${path.cwd}/.tmp/${local.name}/chart/${local.name}"
  secret_dir         = "${path.cwd}/.tmp/${local.name}/secrets"
  values_file        = "values-${var.server_name}.yaml"
  values_content = {
    global = {
      storage_class = var.default_storage_class
    }
    db_archive = {
      storage_class = var.db_archive_storage_class
    }
    postgres = {
      storage_class = var.postgres_storage_class
    }
    kafka = {
      storage_class = var.kafka_storage_class
      zookeeper_storage_class = var.zookeeper_storage_class
    }
  }
  layer = "services"
  operator_type  = "operators"
  type  = "instances"
  application_branch = "main"
  namespace = var.namespace
  layer_config = var.gitops_config[local.layer]
  dbpassword = var.dbpassword != null && var.dbpassword != "" ? var.dbpassword : random_password.dbpassword.result
  grafanapassword = var.grafanapassword != null && var.grafanapassword != "" ? var.grafanapassword : random_password.grafanapassword.result
}

module setup_clis {
  source = "github.com/cloud-native-toolkit/terraform-util-clis.git"

  clis = ["igc", "jq", "kubectl"]
}

resource random_password dbpassword {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource random_password grafanapassword {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
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
    yaml_dir = local.operator_yaml_dir
    type = local.operator_type
    namespace = var.namespace
    server_name = var.server_name
    layer = local.layer
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
    command = "${path.module}/scripts/create-yaml.sh '${self.triggers.name}' '${self.triggers.chart_dir}' '${self.triggers.yaml_dir}' '${local.values_file}'"

    environment = {
      VALUES_SERVER_CONTENT = yamlencode(local.values_content)
    }
  }
}

resource null_resource create_secrets_yaml {
  depends_on = [null_resource.create_yaml]

  provisioner "local-exec" {
    command = "${path.module}/scripts/create-secrets.sh '${var.namespace}' '${local.secret_dir}'"

    environment = {
      BIN_DIR = module.setup_clis.bin_dir
      DB_USER = var.dbuser
      DB_PASSWORD = local.dbpassword
      GRAFANA_USER = var.grafanauser
      GRAFANA_PASSWORD = local.grafanapassword
    }
  }
}

module seal_secrets {
  depends_on = [null_resource.create_secrets_yaml]

  source = "github.com/cloud-native-toolkit/terraform-util-seal-secrets.git"

  source_dir    = local.secret_dir
  dest_dir      = "${local.yaml_dir}/templates"
  kubeseal_cert = var.kubeseal_cert
  label         = local.name
}

resource null_resource setup_gitops {
  depends_on = [null_resource.create_yaml, null_resource.create_secrets_yaml, module.seal_secrets]

  triggers = {
    name = local.name
    yaml_dir = local.yaml_dir
    type = local.type
    namespace = var.namespace
    server_name = var.server_name
    layer = local.layer
    git_credentials = yamlencode(var.git_credentials)
    gitops_config   = yamlencode(var.gitops_config)
    bin_dir = local.bin_dir
  }

  provisioner "local-exec" {
    command = "${self.triggers.bin_dir}/igc gitops-module '${self.triggers.name}' -n '${self.triggers.namespace}' --contentDir '${self.triggers.yaml_dir}' --serverName '${self.triggers.server_name}' -l '${self.triggers.layer}' --type '${self.triggers.type}' --valueFiles 'values.yaml,${local.values_file}'"

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
