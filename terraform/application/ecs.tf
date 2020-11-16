
#
# NOTE: I may also make an EKS cluster to contrast the two
#

resource "aws_ecs_cluster" "app_cluster" {
  name = "my-app-cluster"
}

// log group for ECS app
resource "aws_cloudwatch_log_group" "api" {
  name              = "awslogs-${local.app_name}"
  retention_in_days = 30

  tags = local.global_tags
}

// Note: Passing "tag" as an arg, it may be possible to adjust that so it takes an adjustable build SHA?
resource "aws_ecs_task_definition" "app_service" {
  family                = "app_service"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  cpu                      = 256
  memory                   = 2048
  requires_compatibilities = ["FARGATE"]
  // double-check network mode?
  network_mode             = "awsvpc" 
  container_definitions = templatefile("ecs_task_definition.json.tpl", {
    app_port = 80,
    application_name = local.app_name,
    aws_ecr_repository = aws_ecr_repository.main_ecr.repository_url
    tag                = "latest"
  })
  tags = local.global_tags
}


// NOTE: For now doing basic rolling updates and not fancy blue/green as that requires more CodeDeploy setup
resource "aws_ecs_service" "app" {
  name            = "my_app"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.app_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks.id]
    subnets          = data.aws_subnet_ids.default.ids
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api_target.arn
    container_name   = local.app_name
    container_port   = 80
  }

  depends_on = [aws_lb_listener.http_forward, aws_iam_role_policy_attachment.ecs_task_execution_role]
}

#
# IAM policy
#

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs-${var.deploy_env}-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_role.json

  tags = local.global_tags
}

data "aws_iam_policy_document" "ecs_task_execution_role" {
  version = "2012-10-17"
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

// TODO: secure this to HTTP/HTTPS only
resource "aws_security_group" "ecs_tasks" {
  name        = "ecs-tasks-sg"
  description = "allow inbound access from the ALB only"

  ingress {
    protocol        = "-1"
    from_port       = 0
    to_port         = 0
    cidr_blocks     = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.global_tags
}