variable "demo_app_cluster_name" {
  description = "ECS Cluster Name"
  type        = string
}

variable "ecs_task_execution_role_name" {
  description = "ECS Task Execution Role Name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "frontend_service_name" {
  description = "Frontend ECS Service Name"
  type        = string
}

variable "backend_service_name" {
  description = "Backend ECS Service Name"
  type        = string
}

variable "frontend_task_family" {
  description = "Frontend Task Family"
  type        = string
}

variable "backend_task_family" {
  description = "Backend Task Family"
  type        = string
}

variable "frontend_ecr_repo_url" {
  description = "Frontend ECR Repo URL"
  type        = string
}

variable "backend_ecr_repo_url" {
  description = "Backend ECR Repo URL"
  type        = string
}

variable "frontend_container_port" {
  description = "Frontend Container Port"
  type        = number
  default     = 80
}

variable "backend_container_port" {
  description = "Backend Container Port"
  type        = number
  default     = 3001
}

variable "frontend_alb_listener_arn" {
  description = "ARN of the Frontend ALB Listener"
  type        = string
}

variable "backend_alb_listener_arn" {
  description = "ARN of the Backend ALB Listener"
  type        = string
}

variable "public_alb_sg_id" {
  description = "Security Group ID of the Public ALB"
  type        = string
}

variable "internal_alb_sg_id" {
  description = "Security Group ID of the Internal ALB"
  type        = string
}

variable "frontend_env_vars" {
  description = "List of environment variables for the Frontend container"
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

variable "environment" {
  description = "Environment configuration"
  type = object({
    name           = string
    network_prefix = string
  })
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}