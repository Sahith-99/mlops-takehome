module "eks" {
  source = "./modules/eks-cluster"

  project_name         = var.project_name
  env                  = var.env
  aws_region           = var.aws_region
  vpc_cidr             = var.vpc_cidr
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs

  cluster_version   = var.cluster_version
  cluster_log_types = var.cluster_log_types
  node_groups       = var.node_groups
}
