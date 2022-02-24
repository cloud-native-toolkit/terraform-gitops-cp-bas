
variable "gitops_config" {
  type        = object({
    boostrap = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
    })
    infrastructure = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
      payload = object({
        repo = string
        url = string
        path = string
      })
    })
    services = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
      payload = object({
        repo = string
        url = string
        path = string
      })
    })
    applications = object({
      argocd-config = object({
        project = string
        repo = string
        url = string
        path = string
      })
      payload = object({
        repo = string
        url = string
        path = string
      })
    })
  })
  description = "Config information regarding the gitops repo structure"
}

variable "git_credentials" {
  type = list(object({
    repo = string
    url = string
    username = string
    token = string
  }))
  description = "The credentials for the gitops repo(s)"
  sensitive   = true
}

variable "namespace" {
  type        = string
  description = "The namespace where the application should be deployed"
}

variable "kubeseal_cert" {
  type        = string
  description = "The certificate/public key used to encrypt the sealed secrets"
  default     = ""
}

variable "server_name" {
  type        = string
  description = "The name of the server"
  default     = "default"
}

variable "dbuser" {
  type        = string
  description = "The (mongodb) database user"
  default     = "dbuser"
}

variable "dbpassword" {
  type        = string
  description = "The (mongodb) database password"
  sensitive   = true
}

variable "grafanauser" {
  type        = string
  description = "The grafana user"
  default     = "gfuser"
}

variable "grafanapassword" {
  type        = string
  description = "The grafana password"
  sensitive   = true
}

variable "default_storage_class" {
  type        = string
  description = "The default storage class for the resources"
}

variable "db_archive_storage_class" {
  type        = string
  description = "Storage class for the db_archive resource"
}

variable "postgres_storage_class" {
  type        = string
  description = "Storage class for the postgres resource"
}

variable "kafka_storage_class" {
  type        = string
  description = "Storage class for the kafka resource"
}

variable "zookeeper_storage_class" {
  type        = string
  description = "Storage class for the zookeeper resource"
}
