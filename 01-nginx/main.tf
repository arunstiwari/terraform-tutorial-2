# 1. Create VPC
resource "aws_vpc" "nginx_vpc" {
  cidr_block = var.cidr_block
  instance_tenancy = var.instance_tenancy
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support = var.enable_dns_support
  tags = {
    Name = "${var.prefix}-vpc"
  }
}

# 2. Create Public Subnet
resource "aws_subnet" "nginx_subnet" {
  count = length(data.aws_availability_zones.availability.names)
  vpc_id = aws_vpc.nginx_vpc.id
  map_public_ip_on_launch = "true"
  availability_zone = element(data.aws_availability_zones.availability.names.*,count.index)
  cidr_block = element(var.subnet_cidr_block, count.index)
  tags = {
    Name = "${var.prefix}-pub-subnet-${count.index}"
  }
}

# 3. Create an Internet Gateway
