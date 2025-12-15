module "ecr" {
  source = "../modules/ecr"
  backend_ecr_repo_name  = "app-backend-repo"
  frontend_ecr_repo_name = "app-frontend-repo"
}

terraform {
  cloud {
    organization = "myiacterracloud"

    workspaces {
      name = "wsterracloud-shared"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}
