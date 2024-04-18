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
  instance_type          = "t3.xlarge"
  availability_zone      = "us-east-1a"
  key_name               = "cloudbees-demo"
  associate_public_ip_address = true


  tags = {
    Name = "DemoArtifactoryServer"
  }
  
}
