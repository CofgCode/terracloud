output "instance_ami" {
  value = aws_instance.blog.ami
}

output "instance_arn" {
  value = aws_instance.blog.arn
}

output "environment_url" {
  value = aws_lb.front_end.dns_name

}

output "vpc_id" {
  value = module.blog_vpc.vpc_id
}

output "public_subnets" {
  value = module.blog_vpc.public_subnets
}

output "private_subnets" {
  value = module.blog_vpc.private_subnets
}

output "frontend_alb_listener_arn" {
  value = aws_lb_listener.front_end.arn
}

output "backend_alb_listener_arn" {
  value = aws_lb_listener.internal_backend.arn
}

output "public_alb_sg_id" {
  value = module.blog_sg.security_group_id
}

output "internal_alb_sg_id" {
  value = aws_security_group.internal_lb_sg.id
}
