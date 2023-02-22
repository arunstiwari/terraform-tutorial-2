# 1. Create ECS cluster
resource "aws_ecs_cluster" "jenkins_cluster" {
  name = "jenkins-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags = {
    Name = "jenkins-cluster"
  }
}

#2. ECS Task Definition
resource "aws_ecs_task_definition" "jenkins_task_definition" {
  family                = "jenkins-task-family"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn = aws_iam_role.jenkins_task_execution_role.arn
  cpu = 2048
  memory = 4096
  container_definitions = jsonencode([
    {
      name      = "jenkins-container"
      image     = "jenkins/jenkins:lts-jdk11"
      cpu       = 2048
      memory    = 4096
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        },
        {
          containerPort = 50000
          hostPort      = 50000
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = "/jenkins/server"
          awslogs-region = "ap-south-1"
          awslogs-stream-prefix = "jenkins"
        }
      }
    },
  ])
}

#2.5 IAM Execution Policy Document
data "aws_iam_policy_document" "jenkins_policy_document" {
  version = "2012-10-17"
  statement {
    sid = ""
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
  }
}

# 3.  Task Execution IAM role
resource "aws_iam_role" "jenkins_task_execution_role" {
  name = "jenkins-task_execution_role"
  assume_role_policy = data.aws_iam_policy_document.jenkins_policy_document.json
}

# 4. ecs task execution role policy attachment
resource "aws_iam_role_policy_attachment" "jenkins_task_execution_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.jenkins_task_execution_role.name
}

# 4.5 Security Group for ECS Service
resource "aws_security_group" "jenkins_ecs_service_sg" {
  name = "jenkins-ecs-service-sg"
  vpc_id = "vpc-0baa871294701ff61"
  tags = {
    Name = "jenkins-ecs-service-sg"
  }
  ingress {
    from_port = 0
    protocol  = "tcp"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 5. Create ECS Service
resource "aws_ecs_service" "jenkins_service" {
  name = "jenkins-service"
  cluster = aws_ecs_cluster.jenkins_cluster.id
  task_definition = aws_ecs_task_definition.jenkins_task_definition.arn
  desired_count = 1
  launch_type = "FARGATE"
  network_configuration {
    subnets = ["subnet-007684c01a11622dd"]
    security_groups = [aws_security_group.jenkins_ecs_service_sg.id]
    assign_public_ip = true
  }
}

# 6. Create Log Group
resource "aws_cloudwatch_log_group" "jenkins_cloudwatch_log_group" {
  name = "/jenkins/server"
  retention_in_days = 30
  tags = {
    Environment = "production"
    Application = "Jenkins"
  }
}

# 7. Create Log stream
resource "aws_cloudwatch_log_stream" "jenkins_cloudwatch_log_stream" {
  log_group_name = aws_cloudwatch_log_group.jenkins_cloudwatch_log_group.name
  name           = "jenkins"
}