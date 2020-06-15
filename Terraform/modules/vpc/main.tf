# Creating VPC.
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = var.instance_tenancy
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"

  tags = {
     Name = "${var.name}-vpc"
  }
}

# Private subnet resources -
# Generating private subnets.
resource "aws_subnet" "private_subnet" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.private_subnet_azs, count.index)

  tags = {
     Name = "${var.name}-private-${count.index}",
     "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared",
     "kubernetes.io/role/internal-elb" = 1
  }
}

# Creating route tables.
# We need multiple private route tables as we have multiple NAT gateways.
resource "aws_route_table" "private_route_table"{
  count = length(var.public_subnet_cidrs)

  vpc_id = aws_vpc.vpc.id

  # Default route -> Nat Gateway.
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat_gateway.*.id, count.index)
  }

  tags = {
    Name = "${var.name}-private-route-table-${count.index}"
  }
}

# Creating route table associations.
resource "aws_route_table_association" "private_rta" {
  count = length(var.private_subnet_cidrs)

  # Each private route table needs to be associated with its corresponding subnet.
  subnet_id      = element(aws_subnet.private_subnet.*.id, count.index)
  route_table_id = element(aws_route_table.private_route_table.*.id, count.index)
}


# Public subnet resources -
# Generating public subnets.
resource "aws_subnet" "public_subnet" {
  count = length(var.public_subnet_cidrs)

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.public_subnet_azs, count.index)

  tags = {
     Name = "${var.name}-public-${count.index}",
     "kubernetes.io/cluster/${var.eks_cluster_name}" = "shared",
     "kubernetes.io/role/elb" = 1
  }
}

# Internet gateway.
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.name}-internet-gateway"
  }
}

# Creating Elastic IPs, used in the NAT gateways.
resource "aws_eip" "nat_gateway_eip"{
  count = length(var.private_subnet_cidrs)

  vpc = "true"

  tags = {
    Name = "${var.name}-nat-gateway-eip-${count.index}",
  }
}

# Creating NAT gateways.
# We are creating multiple for HA reasons (if an AZ goes down).
resource "aws_nat_gateway" "nat_gateway" {
  count = length(var.public_subnet_cidrs)

  allocation_id = element(aws_eip.nat_gateway_eip.*.id, count.index)
  subnet_id     = element(aws_subnet.public_subnet.*.id, count.index)

  tags = {
      Name = "${var.name}-nat-gateway-${count.index}"
  }
}

# Route table for public subnets.
resource "aws_route_table" "public_route_table"{
  vpc_id = aws_vpc.vpc.id

  # Default route -> Internet Gateway.
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "${var.name}-public-route-table"
  }
}

# Route table associations for public subnets.
resource "aws_route_table_association" "public_rta" {
  count = length(var.public_subnet_cidrs)

  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public_route_table.id
}


# Auxiliary resources -
# Creating a private Route 53 zone attached to the VPC.
resource "aws_route53_zone" "private_zone" {
  name          = var.hosted_zone_name
  force_destroy = true

  vpc {
    vpc_id = aws_vpc.vpc.id
  }
}

# Rendering and exporting the external-dns template file.
# This is used for both the external-dns and the alb-ingress-controller.
data "template_file" "external_dns_template" {
  template = file("${path.module}/templates/external-dns.tpl")

  vars = {
    hosted_zone_name = var.hosted_zone_name
    hosted_zone_id   = aws_route53_zone.private_zone.id
    cluster_name     = var.eks_cluster_name
  }
}

resource "local_file" "external_dns_output" {
  content  = data.template_file.external_dns_template.rendered
  filename = "${path.root}/external_dns.yaml"
}
