module "sites" {
  source = "../modules/sites"
  environment = {
    name           = "dev"
    network_prefix = "10.0"
  }
  azs = ["us-west-2a"]
}

# --- Shared ECR Lookup ---
data "aws_ecr_repository" "backend" {
  name = "app-backend-repo"
}

data "aws_ecr_repository" "frontend" {
  name = "app-frontend-repo"
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
  
  # Use URLs from Data Source (Shared ECR)
  frontend_ecr_repo_url = data.aws_ecr_repository.frontend.repository_url
  backend_ecr_repo_url  = data.aws_ecr_repository.backend.repository_url
  
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
  
  frontend_desired_count = 1
  backend_desired_count  = 1
}