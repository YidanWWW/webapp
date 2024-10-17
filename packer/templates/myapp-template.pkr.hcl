variable  "aws_region" {
  type = string
  default = "us-east-1"
}

variable "source_ami" 
  type = string
  default = "ami-013b3de8a8fa9b39f"
}

variable "ssh_username" {
  type = string
  default = "ubuntu"
}

variable "vpc_id" {
  type = string
  default = "vpc-0acefcad24c0b914b"
}

variable "subnet_id" {
  type = string
  default = "subnet-02d41e81eddf16052"
}

packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

source "amazon-ebs" "autogenerated_1" {
  ami_name      = "app-image-${formatdate("YYYY_MM_DD_HH_mm", timestamp())}"
  ami_description = "AMI for CSYE 6225"
  instance_type = "t2.small"
  region        = var.aws_region
  ami_regions   = ["us-east-1"]
  ssh_username  = var.ssh_username
  vpc_id        = var.vpc_id
  subnet_id     = var.subnet_id
  source_ami    = var.source_ami
  aws_polling {
    delay_seconds = 120
    max_attempts = 50
  }

  launch_block_device_mappings {
    device_name = "/dev/sda1"
    delete_on_termination = true
    volume_size = 25
    volume_type = "gp2"
  }
}

build {
  sources = ["source.amazon-ebs.autogenerated_1"]

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
      "CHECKPOINT_DISABLE=1"
    ]

    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y nginx",
      "sudo apt-get install -y postgresql postgresql-contrib",
      "sudo systemctl start postgresql",
      "sudo systemctl enable postgresql",

      "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash",
      "export NVM_DIR=\"$HOME/.nvm\"",
      "[ -s \"$NVM_DIR/nvm.sh\" ] && \\. \"$NVM_DIR/nvm.sh\"",
      "[ -s \"$NVM_DIR/bash_completion\" ] && \\. \"$NVM_DIR/bash_completion\"",
      "nvm install 20",
      "nvm use 20",
      "node -v",
      "npm -v",
      "sudo apt-get clean"
    ]

  }

}
