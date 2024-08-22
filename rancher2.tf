# Configure terraform with the required providers
terraform {
  required_providers {
    rke = {
      source = "rancher/rke"
      version = "1.0.1"
    }
    rancher2 = {
      source = "rancher/rancher2"
      version = "1.10.0"
    }
    k8s = {
      source = "hashicorp/kubernetes"
      version = "~> 1.12.0"
    }
  }
}

# Create RKE cluster for Rancher to run on 
resource "rke_cluster" "rancher_server" {
  nodes {
    address = "real.address.goes.here"
    user    = "ubuntu"
    role    = ["controlplane", "worker", "etcd"]
    ssh_key = file("~/.ssh/id_rsa")
  }
}

# Configure k8s provider to use the RKE cluster
provider "kubernetes" {
  alias    = "rancher_server"
  host     = rke_cluster.rancher_server.api_server_url
  username = rke_cluster.rancher_server.kube_admin_user

  client_certificate     = rke_cluster.rancher_server.client_cert
  client_key             = rke_cluster.rancher_server.client_key
  cluster_ca_certificate = rke_cluster.rancher_server.ca_crt
}

# Configure Helm provider to use the RKE cluster
provider "helm" {
  alias = "rke"
  kubernetes {
    host     = rke_cluster.rancher_server.api_server_url
    username = rke_cluster.rancher_server.kube_admin_user

    client_certificate     = rke_cluster.rancher_server.client_cert
    client_key             = rke_cluster.rancher_server.client_key
    cluster_ca_certificate = rke_cluster.rancher_server.ca_crt
  }
}

# Create system namespace
resource "kubernetes_namespace" "cattle-system" {
  provider = kubernetes.rancher_server
  metadata {
    name = "cattle-system"
  }
}

# Install cert-manager on the cluster using helm
resource "helm_release" "cert_manager" {
  provider   = helm.rke
  version    = "v0.16.0"
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = kubernetes_namespace.cattle-system.metadata[0].name
  set {
    name = "installCRDs"
    value = "true"
  }
}

# Enable self-signed certs using helm
resource "helm_release" "selfsigned" {
  provider = helm.rke
  name = "selfsigned"
  chart = "./charts/selfsigned"
  set {
    name = "dnsNames[0]"
    value = "rancher.${rke_cluster.rancher_server.nodes[0].address}"
  }
  depends_on = [helm_release.cert_manager]
}

# Install rancher on the cluster using helm
resource "helm_release" "rancher" {
  provider  = helm.rke
  name      = "rancher"
  chart     = "rancher"
  timeout   = 10000
  repository = "https://releases.rancher.com/server-charts/latest"
  version   = "2.4.5"
  namespace = kubernetes_namespace.cattle-system.metadata[0].name
  set {
    name  = "hostname"
    value = "rancher.${rke_cluster.rancher_server.nodes[0].address}"
  }
  set {
    name  = "ingress.tls.source"
    value = "rancher"
  }
  set {
    name = "certmanager.version"
    value = helm_release.cert_manager.version
  }
  depends_on = [helm_release.selfsigned]
  
}

# Create a rancher provider from the installed rancher, for bootstrapping only
provider "rancher2" {
  alias = "bootstrap"
  api_url   = rke_cluster.rancher_server.api_server_url
  bootstrap = true
  insecure = false
  ca_certs = rke_cluster.rancher_server.ca_crt
  
}

# Bootstrap rancher setup
resource "rancher2_bootstrap" "admin" {
  provider = rancher2.bootstrap
  password = "admin"
  telemetry = false
  depends_on = [helm_release.rancher]
}

# Create actual admin rancher setup
provider "rancher2" {
  alias = "admin"

  api_url = rancher2_bootstrap.admin.url
  token_key = rancher2_bootstrap.admin.token
  insecure = true
}
