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
  profile = "default"
  region  = "ap-northeast-2"
}

resource "aws_vpc" "dev" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "dev env"
  }
}

resource "aws_subnet" "public" {
  cidr_block = cidrsubnet(aws_vpc.dev.cidr_block, 3, 1)
  vpc_id = aws_vpc.dev.id
  availability_zone = "ap-northeast-2a"
}

resource "aws_internet_gateway" "dev" {
  vpc_id = aws_vpc.dev.id
  tags = {
    Name = "dev gateway"
  }
}

resource "aws_route_table" "dev" {
  vpc_id = aws_vpc.dev.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev.id
  }
  tags = {
    Name = "dev route table"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.dev.id
}

resource "aws_security_group" "ingress-all-test" {
  name = "allow-all-sg"
  vpc_id = aws_vpc.dev.id

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }

  egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
}

resource "aws_instance" "ubuntubox" {
  ami           = "ami-05a5333b72d3d1c93"
  instance_type = "t2.micro"
  key_name      = var.key_name
  security_groups = [aws_security_group.ingress-all-test.id]

  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "ubuntu devbox"
  }
}

resource "aws_eip" "ubuntubox" {
  vpc = true
  instance                  = aws_instance.ubuntubox.id
}

output "ubuntubox_ip" {
  value = aws_eip.ubuntubox.public_ip
}

