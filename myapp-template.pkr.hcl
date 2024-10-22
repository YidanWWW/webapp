variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "source_ami" {
  type    = string
  default = "ami-013b3de8a8fa9b39f"
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

variable "vpc_id" {
  type    = string
  default = "vpc-0acefcad24c0b914b"
}

variable "subnet_id" {
  type    = string
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
  ami_name        = "app-image-${formatdate("YYYY_MM_DD_HH_mm", timestamp())}"
  ami_description = "AMI for CSYE 6225"
  instance_type   = "t2.small"
  region          = var.aws_region
  ami_regions     = ["us-east-1"]
  ssh_username    = var.ssh_username
  vpc_id          = var.vpc_id
  subnet_id       = var.subnet_id
  source_ami      = var.source_ami
  aws_polling {
    delay_seconds = 120
    max_attempts  = 50
  }

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    delete_on_termination = true
    volume_size           = 25
    volume_type           = "gp2"
  }
}

build {
  sources = ["source.amazon-ebs.autogenerated_1"]
  # Create csye6225 user
  provisioner "shell" {
    inline = [
      "sudo chmod a+w /home",
      "sudo chmod -R +rwx /home",
      "sudo groupadd csye6225",
      "sudo useradd -s /bin/false -g csye6225 -d /opt/csye6225 -m csye6225",
    ]
  }

  provisioner "file" {
    direction   = "upload"
    source      = "./artifacts/webapp.zip"
    destination = "/tmp/webapp.zip"
  }

  provisioner "file" {
    source      = "./systemd/webapp.service"
    destination = "/tmp/webapp.service"
  }

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
      "CHECKPOINT_DISABLE=1"
    ]

    inline = [
      # Update package list and upgrade the system
      "sudo apt-get update",
      "sudo apt-get upgrade -y",

      # Install Node.js and npm
      "sudo apt-get install -y nodejs npm",

      # Install unzip utility
      "sudo apt-get install -y unzip",

      # Prepare the application directory
      "sudo mkdir -p /opt/csye6225/web-app",
      "sudo chmod -R 755 /opt/csye6225/web-app",
      "sudo ls -ld /opt/csye6225/web-app",
      "sudo unzip /tmp/webapp.zip -d /opt/csye6225/web-app",
      "sudo cp /opt/csye6225/web-app/systemd/webapp.service /etc/systemd/system/",

      # Install dependencies and set up the application
      "cd /opt/csye6225/web-app",
      "sudo npm install",
      "sudo apt-get remove --purge -y git",
      "sudo chown -R csye6225:csye6225 /opt/csye6225",
      "sudo chmod -R 700 /opt/csye6225",

      # Download and install the CloudWatch Agent
      "echo 'Downloading the CloudWatch Agent package...'",
      "sudo wget https://s3.amazonaws.com/amazoncloudwatch-agent/debian/amd64/latest/amazon-cloudwatch-agent.deb",
      "echo 'Installing the CloudWatch Agent package...'",
      "sudo dpkg -i ./amazon-cloudwatch-agent.deb",

      # Set up services
      "sudo systemctl daemon-reload",
      "sudo systemctl enable amazon-cloudwatch-agent webapp",
      "sudo systemctl start amazon-cloudwatch-agent webapp",

      # Cleanup
      "sudo rm -f ./amazon-cloudwatch-agent.deb",
      "sudo rm -rf /home/admin/webapp.zip"
    ]

  }

}
