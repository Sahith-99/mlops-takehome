env = "prod"
project_name = "mlops-platform"

node_groups = {
  ng-generic = {
    desired_size   = 4
    min_size       = 4
    max_size       = 8
    instance_types = ["m5.xlarge"]
  }
  ng-spot = {
    desired_size   = 2
    min_size       = 2
    max_size       = 6
    instance_types = ["m5.large","m5a.large"]
  }
}
