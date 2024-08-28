##############################################################################
# COPYRIGHT Ericsson 2019
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
##############################################################################

# VPC definition for the ENM EKS cluster.

# Fetch available availability_zones in the region.
data "aws_availability_zones" "available" {}

locals {
  aws_vpc_name                     = "${local.cluster-name}-eks-enm-vpc-${random_string.generator.result}"
  aws_subnet_name                  = "${local.cluster-name}-eks-enm-${random_string.generator.result}"
  aws_internet_gateway_name        = "${local.cluster-name}-eks-enm-igw-${random_string.generator.result}"
  aws_route_table_name             = "${local.cluster-name}-eks-enm-rt-${random_string.generator.result}"
}

# VPC definition for ENM.
resource "aws_vpc" "enm" {
  cidr_block = "${var.vpc-subnet-cidr}"

  tags = "${
    map(
     "Name", "${local.aws_vpc_name}",
     "kubernetes.io/cluster/${local.cluster-name}", "shared"
     )
  }"
}

# Subnet definition for ENM.
resource "aws_subnet" "enm" {
  count = "${length(data.aws_availability_zones.available.names)}"

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "${cidrsubnet(var.vpc-subnet-cidr, 8, count.index )}"
  vpc_id            = "${aws_vpc.enm.id}"

  tags = "${
    map(
     "Name", "${local.aws_subnet_name}",
     "kubernetes.io/cluster/${local.cluster-name}", "shared"
    )
  }"
}

# Aws gateway definition to route traffic from public subnets
resource "aws_internet_gateway" "eks" {
  vpc_id = "${aws_vpc.enm.id}"

  tags {
    Name = "${local.aws_internet_gateway_name}"
  }
}

# Main route table definition for the ENM EKS VPC.
resource "aws_route_table" "enm" {
  vpc_id = "${aws_vpc.enm.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.eks.id}"
  }

  tags {
    Name = "${local.aws_route_table_name}"
  }
}

resource "aws_route_table_association" "eks" {
  count = "${length(data.aws_availability_zones.available.names)}"

  subnet_id      = "${aws_subnet.enm.*.id[count.index]}"
  route_table_id = "${aws_route_table.enm.id}"
}
