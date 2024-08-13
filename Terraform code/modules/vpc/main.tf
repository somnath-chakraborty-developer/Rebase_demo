# modules/vpc/main.tf
 provider "aws" {
  region = "us-east-1"
}
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Demo VPC"
  }
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]  # Ensure subnets are in different AZs
  map_public_ip_on_launch = true

  tags = {
    Name = "Demo Subnet"
  }
}

data "aws_availability_zones" "available" {}
