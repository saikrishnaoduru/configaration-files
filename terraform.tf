vpc.tf:-
-------

provider "aws" {
  region = "us-east-1"
  resource "aws_vpc" "kubernetes" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "kubernetes"
    }
}
resource "aws_internet_gateway" "kubernetes_vpc_igw" {
  vpc_id = aws_vpc.kubernetes.id
  tags = {
    Name = "kubernetes_vpc_igw"
    }
}

resource "aws_subnet" "kubernetes_subnets" {
  count                    = length(var.subnets_cidr)
  vpc_id                   = aws_vpc.kubernetes.id
  cidr_block               = element(var.subnets_cidr, count.index)
  availability_zone        = element(var.availability_zones, count.index)
  map_public_ip_on_launch  = true
  tags = {
    Name = "kubernetes_subnets_${count.index + 1}"
  }
}  
  
resource "aws_route_table" "kubernetes_public_rt" {
  vpc_id  = aws_vpc.kubernetes.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kubernetes_vpc_igw.id
  }
  tags = {
    Name = "kubernetes_vpc_public_rt"
  }
}

-------------------------------------------------------------------------------------

variables.tf:--
------------

variable "aws_region" {
  default = "us-east-1"
}
variable "key_name" {
  default = "Devops"
}
variable "vpc_cidr" {
  default = "172.0.0.0/24"
}
variable "subnets_cidr" {
  type    = list(string)
  default = ["172.0.0.0/25", "172.0.0.128/25"]
}
variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}
variable "kubernetes_ami" {
  default = "ami-05fa00d4c63e32376"
}
variable "master_instance_type" {
  default = "t2.medium"
}
variable "worker_instance_type" {
  default = "t2.micro"
}

--------------------------------------------------------------------------------------

security-groups.tf:-
------------------

resource "aws_security_group" "kubernetes_sg" {
  name        = "Allow_All_Ports"
  description = "Allow All Ports All Protocals"
  vpc_id      = aws_vpc.kubernetes.id
  ingress {
    from_port    = 0
    to_port      = 0
    protocol     = "-1"
    cidr_blocks  = ["0.0.0.0/0"]
  }
  
  egress {
    from_port    = 0
    to_port      = 0
    protocol     = "-1"
    cidr_blocks  = ["0.0.0.0/0"]
  }
}  
  


instances.tf:-
------------

   
resource "aws_instance" "kubernetes_Servers" {
  count                   = 1
  ami                     = var.kubernetes_ami
  instance_type           = var.master_instance_type
  vpc_security_group_ids  = [aws_security_group.kubernetes_sg.id]
  subnet_id               = element(aws_subnet.kubernetes_subnets.*.id, count.index)
  key_name                = var.key_name
  
  tags  = {
    Name = "kubernetes_Servers"
    Type = "kubernetes_Master"
  }
}

resource "aws_instance" "kubernetes_Workers" {
  count                   = 2
  ami                     = var.kubernetes_ami
  instance_type           = var.worker_instance_type
  vpc_security_group_ids  = [aws_security_group.kubernetes_sg.id]
  subnet_id               = element(aws_subnet.kubernetes_subnets.*.id, count.index)
  key_name                = var.key_name
  
  tags  = {
    Name = "kubernetes_Servers"
    Type = "kubernetes_Workers"
  }
}



























