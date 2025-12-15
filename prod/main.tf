module  "prod" {
 source = "../modules/sites"
  environment = {
    name           = "prod"
    network_prefix = "10.2"
  }

  asg_max_size = 1
  asg_min_size = 1

}