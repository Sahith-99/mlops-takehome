env = "dev"
project_name = "mlops-platform"

node_groups = {
  ng-general = {
    desired_size   = 2
    min_size       = 2
    max_size       = 3
    instance_types = ["t3.large"]
  }
}
