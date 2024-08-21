terraform {
  required_version = "= v1.9.4"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "= 2.5.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.6.2"
    }
  }
}

# resource "local_file" "terraform-introduction" {
#   content  = "Hi guys, this is the tutorial of Terraform from pkslow.com"
#   filename = "${path.module}/terraform-introduction-by-pkslow.txt"
# }


module "local-file" {
  source  = "./module/random-file"
  prefix  = "pkslow"
  content = "Hi guys, this is www.pkslow.com\nBest wishes!"
}

module "larry-file" {
  source  = "./module/random-file"
  prefix  = "larrydpk"
  content = "Hi guys, this is Larry Deng!"
}

module "echo-larry-result" {
  source  = "matti/resource/shell"
  version = "1.5.0"
  command = "type ${module.larry-file.file_name}"
}