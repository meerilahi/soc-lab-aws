
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "soc-lab"
}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "admin_cidr" {
  description = "Your current public IPv4 address followed by /32"
  type        = string

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0))
    error_message = "Enter a valid IPv4 CIDR, such as 203.0.113.10/32."
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "lab" {
  key_name   = "soc-lab-key"
  public_key = file(pathexpand("~/.ssh/aws-soc-lab.pub"))

  tags = {
    Project = "Mini-SOC-Lab"
  }
}

resource "aws_security_group" "lab" {
  name        = "soc-lab-restricted-sg"
  description = "SSH access restricted to the lab owner current IP"

  ingress {
    description = "SSH from my workstation only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  ingress {
    description = "Web lab access from my workstation only"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  egress {
    description = "Outbound connectivity for updates and Wazuh Cloud"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = "Mini-SOC-Lab"
  }
}

resource "aws_instance" "soc_lab" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.lab.key_name
  vpc_security_group_ids      = [aws_security_group.lab.id]
  associate_public_ip_address = true

  root_block_device {
    volume_size           = 12
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name    = "soc-lab-ubuntu"
    Project = "Mini-SOC-Lab"
  }
}

output "instance_public_ip" {
  value = aws_instance.soc_lab.public_ip
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/aws-soc-lab ubuntu@${aws_instance.soc_lab.public_ip}"
}
