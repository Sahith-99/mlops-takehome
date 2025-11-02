variable "env" {
  type        = string
  description = "Environment name (dev|stg|prod)"
  validation {
    condition     = contains(["dev","stg","prod"], var.env)
    error_message = "env must be one of dev, stg, or prod."
  }
}

variable "project_name" {
  type        = string
  description = "Logical project/system name (e.g., mlops-platform)"
  default     = "mlops-platform"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
  default     = "10.40.0.0/16"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnet CIDRs"
  default     = ["10.40.0.0/20", "10.40.16.0/20"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnet CIDRs"
  default     = ["10.40.128.0/20", "10.40.144.0/20"]
}

variable "node_groups" {
  description = "Node group map keyed by name"
  type = map(object({
    desired_size   = number
    min_size       = number
    max_size       = number
    instance_types = list(string)
  }))
  default = {
    ng-general = {
      desired_size   = 2
      min_size       = 2
      max_size       = 4
      instance_types = ["t3.large"]
    }
  }
}

variable "cluster_version" {
  type        = string
  description = "EKS cluster version"
  default     = "1.30"
}

variable "cluster_log_types" {
  type        = list(string)
  description = "Enabled EKS control plane log types"
  default     = ["api","audit","authenticator","controllerManager","scheduler"]
}
