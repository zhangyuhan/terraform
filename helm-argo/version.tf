terraform {
  required_version = "> 0.13.0"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.15.0"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "D:/workSpace/terraform/helm-argo/k3s.yaml"
  }

}
