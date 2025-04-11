provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "tf_state" {
  bucket = "my-terraform-state-bucket-0015"

 
  lifecycle {
    # prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "versioning_example" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = "terraform-lock-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}



module "network" {
  source             = "./modules/network"
  vpc_cidr           = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets    = ["10.0.3.0/24", "10.0.4.0/24"]
  availability_zones = ["us-east-1a", "us-east-1b"]
}

module "security" {
  source = "./modules/security"
  vpc_id = module.network.vpc_id
}

module "iam" {
  source = "./modules/iam"
}

module "alb" {
  source = "./modules/alb"
  vpc_id = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  alb_sg_id = module.security.alb_sg_id
}

module "ecs" {
  source                   = "./modules/ecs"
  private_subnet_ids       = module.network.private_subnet_ids
  ecs_sg_id                = module.security.ecs_sg_id
  cluster_name             = "my-ecs-cluster"
  container_image          = "gauravrajlaxmi15/simple-test-service"
  container_port           = 5000
  target_group_arn         = module.alb.target_group_arn
  task_execution_role_arn  = module.iam.task_execution_role_arn
}
















# # VPC
# resource "aws_vpc" "main" {
#   cidr_block           = "10.0.0.0/16"
#   enable_dns_support   = true
#   enable_dns_hostnames = true

#   tags = {
#     Name = "main-vpc"
#   }
# }

# # Internet Gateway
# resource "aws_internet_gateway" "gw" {
#   vpc_id = aws_vpc.main.id

#   tags = {
#     Name = "main-igw"
#   }
# }

# # Public Route Table
# resource "aws_route_table" "public" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.gw.id
#   }

#   tags = {
#     Name = "public-rt"
#   }
# }

# # Subnets
# resource "aws_subnet" "public_1" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = "10.0.1.0/24"
#   availability_zone       = "us-east-1a"
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "public-subnet-1"
#   }
# }

# resource "aws_subnet" "public_2" {
#   vpc_id                  = aws_vpc.main.id
#   cidr_block              = "10.0.2.0/24"
#   availability_zone       = "us-east-1b"
#   map_public_ip_on_launch = true

#   tags = {
#     Name = "public-subnet-2"
#   }
# }

# resource "aws_subnet" "private_1" {
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = "10.0.3.0/24"
#   availability_zone = "us-east-1a"

#   tags = {
#     Name = "private-subnet-1"
#   }
# }

# resource "aws_subnet" "private_2" {
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = "10.0.4.0/24"
#   availability_zone = "us-east-1b"

#   tags = {
#     Name = "private-subnet-2"
#   }
# }

# # Associate public subnets with public route table
# resource "aws_route_table_association" "a" {
#   subnet_id      = aws_subnet.public_1.id
#   route_table_id = aws_route_table.public.id
# }

# resource "aws_route_table_association" "b" {
#   subnet_id      = aws_subnet.public_2.id
#   route_table_id = aws_route_table.public.id
# }

# # Elastic IP for NAT Gateway
# resource "aws_eip" "nat" {
#  domain = "vpc"


#   tags = {
#     Name = "nat-eip"
#   }
# }

# # NAT Gateway in Public Subnet 1 (could be any public subnet)
# resource "aws_nat_gateway" "nat" {
#   allocation_id = aws_eip.nat.id
#   subnet_id     = aws_subnet.public_1.id

#   tags = {
#     Name = "main-nat-gateway"
#   }

#   depends_on = [aws_internet_gateway.gw]
# }

# # Private Route Table
# resource "aws_route_table" "private" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.nat.id
#   }

#   tags = {
#     Name = "private-rt"
#   }
# }

# # Associate Private Subnets with Private Route Table
# resource "aws_route_table_association" "private_1" {
#   subnet_id      = aws_subnet.private_1.id
#   route_table_id = aws_route_table.private.id
# }

# resource "aws_route_table_association" "private_2" {
#   subnet_id      = aws_subnet.private_2.id
#   route_table_id = aws_route_table.private.id
# }

# resource "aws_ecs_cluster" "main" {
#   name = "my-ecs-cluster"
# }

# resource "aws_security_group" "ecs_tasks" {
#   name        = "ecs-tasks-sg"
#   description = "Allow traffic from ALB"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     from_port       = 5000
#     to_port         = 5000
#     protocol        = "tcp"
#     security_groups = [aws_security_group.alb.id] # Only ALB allowed
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_security_group" "alb" {
#   name        = "alb-sg"
#   description = "Allow HTTP inbound"
#   vpc_id      = aws_vpc.main.id

#   ingress {
#     from_port   = 5000
#     to_port     = 5000
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_lb" "app" {
#   name               = "ecs-lb"
#   load_balancer_type = "application"
#   subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
#   security_groups    = [aws_security_group.alb.id]
# }

# resource "aws_lb_target_group" "ecs_tg" {
#   name     = "ecs-tg-5000"
#   port     = 5000
#   protocol = "HTTP"
#   vpc_id   = aws_vpc.main.id
#   target_type = "ip"
#   health_check {
#     path = "/"
#     protocol = "HTTP"
#   }
# }

# resource "aws_lb_listener" "http" {
#   load_balancer_arn = aws_lb.app.arn
#   port              = 5000
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.ecs_tg.arn
#   }
# }

# resource "aws_ecs_task_definition" "app" {
#   family                   = "my-ecs-task"
#   network_mode             = "awsvpc"
#   requires_compatibilities = ["FARGATE"]
#   cpu                      = "256"
#   memory                   = "512"
#   execution_role_arn       = aws_iam_role.ecs_task_execution.arn

#   container_definitions = jsonencode([
#     {
#       name      = "my-app"
#       image     = "gauravrajlaxmi15/simple-test-service" # Replace with your own image
#       portMappings = [{
#         containerPort = 5000
#         hostPort      = 5000
#         protocol      = "tcp"
#       }]
#     }
#   ])
# }

# resource "aws_iam_role" "ecs_task_execution" {
#   name = "ecsTaskExecutionRole"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Action = "sts:AssumeRole",
#       Principal = {
#         Service = "ecs-tasks.amazonaws.com"
#       },
#       Effect = "Allow",
#       Sid    = ""
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
#   role       = aws_iam_role.ecs_task_execution.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
# }

# resource "aws_ecs_service" "app" {
#   name            = "my-ecs-service"
#   cluster         = aws_ecs_cluster.main.id
#   task_definition = aws_ecs_task_definition.app.arn
#   launch_type     = "FARGATE"
#   desired_count   = 1

#   network_configuration {
#     subnets         = [aws_subnet.private_1.id, aws_subnet.private_2.id]
#     security_groups = [aws_security_group.ecs_tasks.id]
#     assign_public_ip = false
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.ecs_tg.arn
#     container_name   = "my-app"
#     container_port   = 5000
#   }

#   depends_on = [aws_lb_listener.http]
# }
