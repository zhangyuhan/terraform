terraform {
  required_version = "v1.9.4"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.15"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = local_sensitive_file.kubeconfig.filename
  }
}
