resource "aws_ssm_parameter" "backend_url" {
  name  = "/${var.environment.name}/backend/url"
  type  = "String"
  value = "http://${aws_lb.front_end.dns_name}/api"

  tags = {
    Environment = var.environment.name
    Project     = "Container application"
  }
}
