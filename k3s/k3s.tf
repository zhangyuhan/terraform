module "k3s" {
  source                   = "xunleii/k3s/module"
  k3s_version              = "v1.30.3+k3s1"
  generate_ca_certificates = true
  global_flags = [
    "--tls-san 192.168.157.134",
    "--write-kubeconfig-mode 644",
    "--disable=traefik",
    "--kube-controller-manager-arg bind-address=0.0.0.0",
    "--kube-proxy-arg metrics-bind-address=0.0.0.0",
    "--kube-scheduler-arg bind-address=0.0.0.0"
  ]
  k3s_install_env_vars = {}

  servers = {
    "k3s" = {
      ip = "192.168.157.134"
      connection = {
        timeout  = "60s"
        # type     = "ssh"
        host     = "192.168.157.134"
        private_key = file("./id_rsa")
        # password = var.password
        user     = "root"
      }
    }
  }
}

resource "local_sensitive_file" "kubeconfig" {
  content  = module.k3s.kube_config
  filename = "${path.module}/config.yaml"
}
