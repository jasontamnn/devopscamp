module "k3s" {
  source      = "./modules/k3s"
  public_ip   = module.cvm.public_ip
  private_ip  = module.cvm.private_ip
  server_name = "terraform-k3s-server"
}

module "cvm" {
  source        = "./modules/cvm"
  secret_id     = var.secret_id
  secret_key    = var.secret_key
  password      = var.password
}

module "cloudflare" {
  source = "./modules/cloudflare"
  domain = var.domain
  prefix = var.prefix
  ip     = module.cvm.public_ip
  values = ["jenkins", "argocd"]
}

resource "null_resource" "connect_ubuntu" {
  depends_on = [module.k3s]
  connection {
    host     = module.cvm.public_ip
    type     = "ssh"
    user     = "ubuntu"
    password = var.password
  }

  triggers = {
    script_hash = filemd5("${path.module}/init.sh.tpl")
  }

  provisioner "file" {
    destination = "/tmp/init.sh"
    content = templatefile(
      "${path.module}/init.sh.tpl",
      {}
    )
  }

  provisioner "file" {
    destination = "/tmp/jenkins-service-account.yaml"
    source      = "${path.module}/yaml/jenkins-service-account.yaml"
  }

  provisioner "file" {
    destination = "/tmp/jenkins-values.yaml"
    content = templatefile(
      "${path.module}/yaml/jenkins-values.yaml.tpl",
      {
        "prefix" : "${var.prefix}"
        "domain" : "${var.domain}"
      }
    )
  }

  provisioner "file" {
    destination = "/tmp/github-personal-token.yaml"
    content = templatefile(
      "${path.module}/yaml/github-personal-token.yaml.tpl",
      {
        "github_username" : "${var.github_username}"
        "github_personal_token" : "${var.github_personal_token}"
      }
    )
  }

  provisioner "file" {
    destination = "/tmp/github-repository.yaml"
    content = templatefile(
      "${path.module}/yaml/github-repository.yaml.tpl",
      {
        "github_personal_token" : "${var.github_personal_token}"
      }
    )
  }

  provisioner "file" {
    destination = "/tmp/github-pat-secret-text.yaml"
    content = templatefile(
      "${path.module}/yaml/github-pat-secret-text.yaml.tpl",
      {
        "github_personal_token" : "${var.github_personal_token}"
      }
    )
  }

  provisioner "file" {
    destination = "/tmp/argocd-values.yaml"
    content = templatefile(
      "${path.module}/yaml/argocd-values.yaml.tpl",
      {
        "prefix" : "${var.prefix}"
        "domain" : "${var.domain}"
      }
    )
  }

  provisioner "file" {
    destination = "/tmp/providerConfig.yaml"
    content = templatefile(
      "${path.module}/yaml/providerConfig.yaml.tpl",
      {
        "secret_id" : "${var.secret_id}"
        "secret_key" : "${var.secret_key}"
      }
    )
  }

  provisioner "file" {
    source      = "${path.module}/yaml/provider.yaml"
    destination = "/tmp/provider.yaml"
  }

  provisioner "file" {
    source      = "${path.module}/yaml/argocd-application.yaml"
    destination = "/tmp/argocd-application.yaml"
  }


  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init.sh",
      "sh /tmp/init.sh",
    ]
  }
}