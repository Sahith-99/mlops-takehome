env = "stg"
project_name = "mlops-platform"

node_groups = {
  ng-general = {
    desired_size   = 3
    min_size       = 3
    max_size       = 5
    instance_types = ["m5.large"]
  }
}
