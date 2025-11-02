variable "project_name" { type = string }
variable "env" { type = string }
variable "aws_region" { type = string }

variable "vpc_cidr"             { type = string }
variable "private_subnet_cidrs" { type = list(string) }
variable "public_subnet_cidrs"  { type = list(string) }

variable "cluster_version"   { type = string }
variable "cluster_log_types" { type = list(string) }

variable "node_groups" {
  description = "Map of node group settings keyed by name"
  type = map(object({
    desired_size   = number
    min_size       = number
    max_size       = number
    instance_types = list(string)
  }))
}
