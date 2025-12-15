module "sites" {
  source = "../modules/sites"
  environment = {
    name           = "dev"
    network_prefix = "10.0"
  }
}

module "ecr" {
  source = "../modules/ecr"
  backend_ecr_repo_name  = "dev-backend-repo"
  frontend_ecr_repo_name = "dev-frontend-repo"
}

module "ecs" {
  source = "../modules/ecs"
  
  demo_app_cluster_name        = "dev-cluster"
  ecs_task_execution_role_name = "dev-ecs-task-execution-role"
  
  vpc_id          = module.sites.vpc_id
  public_subnets  = module.sites.public_subnets
  private_subnets = module.sites.private_subnets
  
  frontend_service_name = "dev-frontend-service"
  backend_service_name  = "dev-backend-service"
  
  frontend_task_family = "dev-frontend-task"
  backend_task_family  = "dev-backend-task"
  
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
    name           = "dev"
    network_prefix = "10.0"
  }
  
  aws_region = "us-west-2"
}