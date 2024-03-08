terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-east-1"
}

data "aws_ami" "ubuntu-linux-2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

variable "ssh_private_key_file" {
  default = "cloudbees-demo.pem"
}


resource "aws_instance" "artifactory_server" {
  ami                    = data.aws_ami.ubuntu-linux-2204.id
  instance_type          = "t3.large"
  availability_zone      = "us-east-1a"
  key_name               = "cloudbees-demo"
  associate_public_ip_address = true


  tags = {
    Name = "DemoArtifactoryServer"
  }
  user_data = <<-EOF
    #!/bin/bash
    #Add Docker's official GPG key:
    apt update -y
    apt upgrade -y
    apt install ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    # Add the repository to Apt sources:
    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update -y
    apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    systemctl start docker 
    systemctl enable docker 
    usermod -aG docker ubuntu
    apt install certbot
    touch /tmp/docker-installed.txt
    sleep 20
    echo "docker installed"
    EOF
}

resource "null_resource" "artifactory_server" {
  provisioner "remote-exec" {
    inline = [
      "until [ -f /tmp/docker-installed.txt ]; do sleep 5; done",
      "export JFROG_HOME=~/.jfrog",
      "mkdir -p $JFROG_HOME/artifactory/var/etc/",
      "cd $JFROG_HOME/artifactory/var/etc/",
      "touch ./system.yaml",
      "cd $HOME",
      "sudo chown -R 1030:1030 $JFROG_HOME/artifactory/var",
      "chmod -R 777 $JFROG_HOME/artifactory/var",
      "docker run --name artifactory -v $JFROG_HOME/artifactory/var/:/var/opt/jfrog/artifactory -d -p 8081:8081 -p 8082:8082 releases-docker.jfrog.io/jfrog/artifactory-oss:7.77.5"
      ]

    connection {
      user        = "ubuntu"
      host        = aws_instance.artifactory_server.public_ip
      agent       = false
      private_key = "${file("./${var.ssh_private_key_file}")}"
    }

  }
}
