# Pick the first two available AZs in the region (e.g., us-east-1a/1c)
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  # ensure we always have at least two AZs for control plane
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}


locals {
  name = "${var.project_name}-${var.env}"
  tags = {
    Project = var.project_name
    Env     = var.env
    Managed = "terraform"
  }
}

# ----------------------
# Networking (simple VPC)
# ----------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(local.tags, { Name = "${local.name}-vpc" })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${local.name}-igw" })
}

resource "aws_subnet" "public" {
  for_each = { for idx, cidr in var.public_subnet_cidrs : idx => cidr }
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  map_public_ip_on_launch = true
  availability_zone       = local.azs[tonumber(each.key) % length(local.azs)]

  tags = merge(local.tags, {
    Name = "${local.name}-public-${each.key}"
    "kubernetes.io/role/elb" = "1"
  })
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${local.name}-public-rt" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# NAT for private subnets
resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = merge(local.tags, { Name = "${local.name}-nat-eip" })
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = values(aws_subnet.public)[0].id
  tags          = merge(local.tags, { Name = "${local.name}-nat" })
  depends_on    = [aws_internet_gateway.this]
}

resource "aws_subnet" "private" {
  for_each = { for idx, cidr in var.private_subnet_cidrs : idx => cidr }
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  map_public_ip_on_launch = false
  availability_zone       = local.azs[tonumber(each.key) % length(local.azs)]

  tags = merge(local.tags, {
    Name = "${local.name}-private-${each.key}"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.tags, { Name = "${local.name}-private-rt" })
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this.id
}

resource "aws_route_table_association" "private_assoc" {
  for_each = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# ----------------------
# Security Groups
# ----------------------
resource "aws_security_group" "cluster" {
  name        = "${local.name}-cluster-sg"
  description = "EKS cluster security group"
  vpc_id      = aws_vpc.this.id
  tags        = merge(local.tags, { Name = "${local.name}-cluster-sg" })
}

resource "aws_security_group" "nodes" {
  name        = "${local.name}-nodes-sg"
  description = "EKS nodes security group"
  vpc_id      = aws_vpc.this.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name}-nodes-sg" })
}

# ----------------------
# IAM roles for EKS
# ----------------------
data "aws_iam_policy_document" "eks_assume" {
  statement {
    effect = "Allow"
    principals { 
	type = "Service" 
    	identifiers = ["eks.amazonaws.com"]
	 }
    	actions = ["sts:AssumeRole"]
  }
}

# Wait and retry IAM attachment for AWS eventual-consistency
resource "time_sleep" "wait_for_iam_role" {
  depends_on      = [aws_iam_role.eks_cluster]
  create_duration = "40s"
}

resource "null_resource" "pause_before_attachment" {
  depends_on = [time_sleep.wait_for_iam_role]
}


resource "aws_iam_role" "eks_cluster" {
  name               = "${local.name}-eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  depends_on = [time_sleep.wait_for_iam_role]
}

#resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSVpcResourceController" {
 # role       = aws_iam_role.eks_cluster.name
 # policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVpcResourceController"
 # depends_on = [time_sleep.wait_for_iam_role]
#}

# Add this instead (attaches the managed policy to the role)
resource "aws_iam_policy_attachment" "eks_vpc_resource_controller_attach" {
  name       = "${local.name}-eks-vpc-resource-controller-attach"
  roles      = [aws_iam_role.eks_cluster.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVpcResourceController"
  depends_on = [null_resource.pause_before_attachment]
}
# Node group role
data "aws_iam_policy_document" "node_assume" {
  statement {
    effect = "Allow"
    principals {
 	type = "Service" 
    	identifiers = ["ec2.amazonaws.com"]
	 }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "node" {
  name               = "${local.name}-eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.node_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}
resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}
resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# ----------------------
# EKS cluster + OIDC
# ----------------------
resource "aws_eks_cluster" "this" {
  name     = "${local.name}-eks"
  version  = var.cluster_version
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids              = concat([for s in aws_subnet.public : s.id], [for s in aws_subnet.private : s.id])
    endpoint_public_access  = true
    endpoint_private_access = true
    security_group_ids      = [aws_security_group.cluster.id]
  }

  enabled_cluster_log_types = var.cluster_log_types

  tags = local.tags
}

data "tls_certificate" "eks_oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
}

# ----------------------
# Node groups
# ----------------------
resource "aws_eks_node_group" "this" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${each.key}"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = [for s in aws_subnet.private : s.id]

  scaling_config {
    desired_size = each.value.desired_size
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  instance_types = each.value.instance_types

  update_config {
    max_unavailable = 1
  }

  tags = merge(local.tags, { Name = "${local.name}-${each.key}" })
  depends_on = [aws_eks_cluster.this]
}
