data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

data "aws_vpc" "default" {
  default = true  
}

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dev"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  # private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  #enable_nat_gateway = true
  #enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_instance" "blog" {
  ami           = data.aws_ami.app_ami.id
  instance_type = var.instance_type
  
  #vpc_security_group_ids = [aws_security_group.blog.id]
  vpc_security_group_ids = [module.blog_sg.security_group_id]
  subnet_id              = module.blog_vpc.public_subnets[0]

  tags = {
    Name = "HelloWorld"
  }
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name               = "blog-alb"
  vpc_id             = module.blog_vpc.vpc_id
  subnets            = module.blog_vpc.public_subnets
  security_groups    = [module.blog_sg.security_group_id]

  listeners = {
    ex-http-https-redirect = {
      port     = 80
      protocol = "HTTP"
    }
    ex-https = {
        forward          = {
        target_group_key = "ex-instance"
      }
    }
  }

  target_groups = {
    ex-instance = {
      name_prefix      = "blog"
      protocol         = "HTTP"
      port             = 80
      target_type      = "instance"
      target_id        = aws_instance.blog.id
    }
  }

  tags = {
    Environment = "Development"
    Project     = "Example"
  }
}


module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"
  name = "blog_new"
  
  # remove public vpc
  #vpc_id              = data.aws_vpc.default.id

  # adds the SG to the non default new vpc 
  vpc_id = module.blog_vpc.vpc_id

  ingress_rules       = ["http-80-tcp","https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]

  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]

}

# resource "aws_security_group"  "blog" {
#   name        = "blog"
#   description = "Allow http  and https in. Allow everything out"

#   vpc_id = data.aws_vpc.default.id

# }

# resource "aws_security_group_rule" "blog_http_in" {
#   type         = "ingress"
#   from_port    = 80
#   to_port      = 80
#   protocol     = "tcp"
#   cidr_blocks  =  ["0.0.0.0/0"] 

#   security_group_id = aws_security_group.blog.id
# }

# resource "aws_security_group_rule" "blog_https_in" {
#   type         = "ingress"
#   from_port    = 443
#   to_port      = 443
#   protocol     = "tcp"
#   cidr_blocks  =  ["0.0.0.0/0"] 

#   security_group_id = aws_security_group.blog.id
# }

# resource "aws_security_group_rule" "blog_everything_out" {
#   type         = "egress"
#   from_port    = 0
#   to_port      = 0
#   protocol     = "-1"
#   cidr_blocks  =  ["0.0.0.0/0"] 

#   security_group_id = aws_security_group.blog.id
# }