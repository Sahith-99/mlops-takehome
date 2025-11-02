output "cluster_name" { value = module.eks.cluster_name }
output "cluster_endpoint" { value = module.eks.cluster_endpoint }
output "cluster_oidc_issuer" { value = module.eks.cluster_oidc_issuer }
output "private_subnet_ids" { value = module.eks.private_subnet_ids }
