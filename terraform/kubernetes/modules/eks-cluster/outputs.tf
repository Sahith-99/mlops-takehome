output "cluster_name"         { value = aws_eks_cluster.this.name }
output "cluster_endpoint"     { value = aws_eks_cluster.this.endpoint }
output "cluster_oidc_issuer"  { value = aws_iam_openid_connect_provider.this.url }
output "private_subnet_ids" {
  value = [for s in aws_subnet.private : s.id]
}

