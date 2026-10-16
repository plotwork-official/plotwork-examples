terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "eu-west-1"
}

# The tracking API and its worker run on ECS Fargate behind one load balancer.
resource "aws_ecs_cluster" "main" {
  name = "parcelpoint"
}

resource "aws_lb" "api" {
  name               = "parcelpoint-api"
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_a.id]
  security_groups    = [aws_security_group.api.id]
}

resource "aws_lb_target_group" "api" {
  name        = "parcelpoint-api"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.api.arn
  port              = 443
  protocol          = "HTTPS"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

resource "aws_ecs_task_definition" "api" {
  family                   = "tracking-api"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  container_definitions = jsonencode([{
    name  = "api"
    image = "ghcr.io/parcelpoint/tracking-api:1.8.2"
    environment = [
      { name = "DATABASE_HOST", value = aws_db_instance.tracking.address },
      { name = "LABELS_BUCKET", value = aws_s3_bucket.labels.bucket },
      { name = "EVENTS_QUEUE", value = aws_sqs_queue.carrier_events.url },
    ]
  }])
}

resource "aws_ecs_task_definition" "worker" {
  family                   = "event-worker"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  container_definitions = jsonencode([{
    name  = "worker"
    image = "ghcr.io/parcelpoint/event-worker:1.8.2"
    environment = [
      { name = "DATABASE_HOST", value = aws_db_instance.tracking.address },
      { name = "EVENTS_QUEUE", value = aws_sqs_queue.carrier_events.url },
    ]
  }])
}

resource "aws_ecs_service" "api" {
  name            = "tracking-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = [aws_subnet.private_a.id]
    security_groups = [aws_security_group.api.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = 8080
  }
}

resource "aws_ecs_service" "worker" {
  name            = "event-worker"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = [aws_subnet.private_a.id]
    security_groups = [aws_security_group.api.id]
  }
}
