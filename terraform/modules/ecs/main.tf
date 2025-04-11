# variable "private_subnet_ids" {}
# variable "ecs_sg_id" {}
# variable "task_execution_role_arn" {}
# variable "target_group_arn" {}

resource "aws_ecs_cluster" "main" {
  name = "my-ecs-cluster"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "my-ecs-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.task_execution_role_arn

  container_definitions = jsonencode([{
    name      = "my-app"
    image     = "gauravrajlaxmi15/simple-test-service"
    portMappings = [{
      containerPort = 5000
      hostPort      = 5000
      protocol      = "tcp"
    }]
  }])
}

resource "aws_ecs_service" "app" {
  name            = "my-ecs-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [var.ecs_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "my-app"
    container_port   = 5000
  }

  depends_on = [aws_ecs_task_definition.app]
}
