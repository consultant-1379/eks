# Make reference other modules here. As a pattern you should not be creating resources directly here.
# Either use a module from the Terraform module registry (https://registry.terraform.io/) or write one yourself

resource "null_resource" "enm-eks" {
  provisioner "local-exec" {
    command = "echo You are deploying the ${var.component-name} component into the ${var.environment-name} environment!"
  }
}

# Create root ssh key to use for EKS workers.
resource "aws_key_pair" "eks" {
  key_name   = "${var.key-name}-${random_string.generator.result}"
  public_key = "${file(var.public-key)}"
}

resource "random_string" "generator" {
  length  = 12
  upper   = true
  lower   = true
  number  = true
  special = false
}
