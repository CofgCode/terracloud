module "sites" {
  source = "../modules/sites"
  environment = {
    name           = "prod"
    network_prefix = "10.2" # Assuming 10.2 for prod, following dev=10.0 pattern or user preference. Let's stick to a different CIDR.
  }
  azs = ["us-west-2a", "us-west-2b"]
}

module "ecr" {
  source = "../modules/ecr"
  backend_ecr_repo_name  = "prod-backend-repo"
  frontend_ecr_repo_name = "prod-frontend-repo"
}

module "ecs" {
  source = "../modules/ecs"
  
  demo_app_cluster_name        = "prod-cluster"
  ecs_task_execution_role_name = "prod-ecs-task-execution-role"
  
  vpc_id          = module.sites.vpc_id
  public_subnets  = module.sites.public_subnets
  private_subnets = module.sites.private_subnets
  
  frontend_service_name = "prod-frontend-service"
  backend_service_name  = "prod-backend-service"
  
  frontend_task_family = "prod-frontend-task"
  backend_task_family  = "prod-backend-task"
  
  frontend_ecr_repo_url = module.ecr.frontend_repository_url
  backend_ecr_repo_url  = module.ecr.backend_repository_url
  
  frontend_container_port = 80
  backend_container_port  = 3001
  
  frontend_alb_listener_arn = module.sites.frontend_alb_listener_arn
  backend_alb_listener_arn  = module.sites.backend_alb_listener_arn
  
  public_alb_sg_id     = module.sites.public_alb_sg_id
  internal_alb_sg_id   = module.sites.internal_alb_sg_id
  
  frontend_env_vars = [
    {
      name  = "VITE_API_URL"
      value = "/api"
    }
  ]

  environment = {
    name           = "prod"
    network_prefix = "10.2"
  }
  
  aws_region = "us-west-2"
  
  frontend_desired_count = 2
  backend_desired_count  = 2
}