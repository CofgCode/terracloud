resource "aws_ecs_cluster" "cluster" {
  name = var.demo_app_cluster_name
  
  tags = {
    Environment = var.environment.name
    Project     = "Container application"
  }
}

# --- CloudWatch Logs ---

resource "aws_cloudwatch_log_group" "frontend_log_group" {
  name = "/ecs/${var.frontend_service_name}"
  retention_in_days = 30

  tags = {
    Environment = var.environment.name
    Project     = "Container application"
  }
}

resource "aws_cloudwatch_log_group" "backend_log_group" {
  name = "/ecs/${var.backend_service_name}"
  retention_in_days = 30

  tags = {
    Environment = var.environment.name
    Project     = "Container application"
  }
}

# --- IAM Roles ---

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = var.ecs_task_execution_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

# Allow logging to CloudWatch
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# --- Security Groups ---

resource "aws_security_group" "app_sg" {
  name        = "${var.demo_app_cluster_name}-app-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.frontend_container_port
    to_port         = var.frontend_container_port
    protocol        = "tcp"
    security_groups = [var.public_alb_sg_id]
    description     = "Allow traffic from Public ALB"
  }

  ingress {
    from_port       = var.backend_container_port
    to_port         = var.backend_container_port
    protocol        = "tcp"
    security_groups = [var.public_alb_sg_id]
     description     = "Allow traffic from Public ALB to Backend (API)"
  }

  ingress {
    from_port       = var.backend_container_port
    to_port         = var.backend_container_port
    protocol        = "tcp"
    security_groups = [var.internal_alb_sg_id]
    description     = "Allow traffic from Internal ALB to Backend"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Environment = var.environment.name
    Project     = "Container application"
  }
}

# --- Frontend Service ---

resource "aws_ecs_task_definition" "frontend" {
  family                   = var.frontend_task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "frontend-container"
      image     = var.frontend_ecr_repo_url
      essential = true
      portMappings = [
        {
          containerPort = var.frontend_container_port
          hostPort      = var.frontend_container_port
        }
      ],
      environment = var.frontend_env_vars
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.frontend_log_group.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "frontend"
        }
      }
    }
  ])
  
  tags = {
    Environment = var.environment.name
    Project     = "Container application"
  }
}

resource "aws_ecs_service" "frontend" {
  name            = var.frontend_service_name
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.frontend.arn
  launch_type     = "FARGATE"
  desired_count   = var.frontend_desired_count

  network_configuration {
    subnets          = var.public_subnets # Frontend needs public IP if pulling from public ECR or using Internet? Actually usually private if NAT, but let's stick to public subnets for simpler demo or private with NAT. User added NAT gateway, so private is better. But existing sites module used public. Let's use vars.
    # WAIT: User added NAT Gateway to private subnets. So we should use PRIVATE subnets for tasks.
    security_groups  = [aws_security_group.app_sg.id]
    assign_public_ip = false # True if public subnet, False if private (w/ NAT).
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend_tg.arn
    container_name   = "frontend-container"
    container_port   = var.frontend_container_port
  }
  
  tags = {
    Environment = var.environment.name
    Project     = "Container application"
  }
}

resource "aws_lb_target_group" "frontend_tg" {
  name        = "${var.environment.name}-frontend-tg"
  port        = var.frontend_container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    path = "/"
  }
  
  tags = {
    Environment = var.environment.name
    Project     = "Container application"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener_rule" "frontend_rule" {
  listener_arn = var.frontend_alb_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }

  condition {
    path_pattern {
      values = ["/frontend*"]
    }
  }
}


# --- Backend Service ---

resource "aws_ecs_task_definition" "backend" {
  family                   = var.backend_task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "backend-container"
      image     = var.backend_ecr_repo_url
      essential = true
      portMappings = [
        {
          containerPort = var.backend_container_port
          hostPort      = var.backend_container_port
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.backend_log_group.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "backend"
        }
      }
    }
  ])
  
  tags = {
    Environment = var.environment.name
    Project     = "Container application"
  }
}

resource "aws_ecs_service" "backend" {
  name            = var.backend_service_name
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.backend.arn
  launch_type     = "FARGATE"
  desired_count   = var.backend_desired_count

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.app_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_internal_tg.arn
    container_name   = "backend-container"
    container_port   = var.backend_container_port
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend_public_tg.arn
    container_name   = "backend-container"
    container_port   = var.backend_container_port
  }
  
  tags = {
    Environment = var.environment.name
    Project     = "Container application"
  }
}

resource "aws_lb_target_group" "backend_internal_tg" {
  name        = "${var.environment.name}-backend-internal-tg"
  port        = var.backend_container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    path = "/health" # Assumed health check
  }
  
  tags = {
    Environment = var.environment.name
    Project     = "Container application"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group" "backend_public_tg" {
  name        = "${var.environment.name}-backend-public-tg"
  port        = var.backend_container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    path = "/health"
  }
  
  tags = {
    Environment = var.environment.name
    Project     = "Container application"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener_rule" "backend_internal_rule" {
  listener_arn = var.backend_alb_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_internal_tg.arn
  }

  condition {
    path_pattern {
      values = ["/*"] # Internal ALB forwards everything to backend
    }
  }
}

resource "aws_lb_listener_rule" "backend_public_rule" {
  listener_arn = var.frontend_alb_listener_arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_public_tg.arn
  }

  condition {
    path_pattern {
      values = ["/api*"]
    }
  }
}