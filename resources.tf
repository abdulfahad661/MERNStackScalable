# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "mern-vpc"
  }
}

# Subnets
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 2)
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "private-subnet-${count.index}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "mern-igw"
  }
}

# Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "public-route-table"
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ECS Cluster
resource "aws_ecs_cluster" "backend" {
  name = "mern-backend-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "backend" {
  family                   = "mern-backend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([{
    name      = "mern-backend"
    image     = "${aws_ecr_repository.mern_backend.repository_url}:latest"
    essential = true
    portMappings = [{
      containerPort = 3000
      hostPort      = 3000
    }]
  }])
}

resource "aws_ecs_task_definition" "frontend" {
  family                   = "mern-frontend-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([{
    name      = "mern-frontend"
    image     = "${aws_ecr_repository.mern_frontend.repository_url}:latest"
    essential = true
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
}

# ECS Service
resource "aws_ecs_service" "backend" {
  name            = "mern-backend-service"
  cluster         = aws_ecs_cluster.backend.id
  task_definition = aws_ecs_task_definition.backend.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = aws_subnet.private[*].id
    security_groups = [aws_security_group.ecs.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "mern-backend"
    container_port   = 3000
  }
}

# ALB
resource "aws_lb" "backend" {
  name               = "mern-backend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id
}

# ALB Listener
resource "aws_lb_listener" "backend" {
  load_balancer_arn = aws_lb.backend.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

resource "aws_lb_target_group" "backend" {
  name        = "mern-backend-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200-299"
  }
}

# ECR Repository
resource "aws_ecr_repository" "mern_backend" {
  name                 = "mern-backend-repo"
  image_tag_mutability = "MUTABLE"
  tags = {
    Name = "mern-backend-repo"
  }
}

resource "aws_ecr_repository" "mern_frontend" {
  name                 = "mern-frontend-repo"
  image_tag_mutability = "MUTABLE"
  tags = {
    Name = "mern-frontend-repo"
  }
}

# ECR Lifecycle Policies
resource "aws_ecr_lifecycle_policy" "mern_backend" {
  repository = aws_ecr_repository.mern_backend.name
  policy     = file("${path.module}/ecr-lifecycle-policy.json")
}

resource "aws_ecr_lifecycle_policy" "mern_frontend" {
  repository = aws_ecr_repository.mern_frontend.name
  policy     = file("${path.module}/ecr-lifecycle-policy.json")
}

# Aurora RDS Cluster
resource "aws_rds_cluster" "aurora" {
  cluster_identifier     = "mern-aurora-cluster"
  engine                 = "aurora-mysql"
  engine_version         = "5.7.mysql_aurora.2.11.1"
  database_name          = var.db_name
  master_username        = var.db_username
  master_password        = var.db_password
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.default.name
}

resource "aws_db_subnet_group" "default" {
  name       = "mern-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id
}

# S3 Bucket
resource "aws_s3_bucket" "static_assets" {
  bucket = "mern-static-assets-${random_id.bucket_suffix.hex}"
  tags = {
    Name = "mern-static-assets"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Security Groups
resource "aws_security_group" "ecs" {
  name   = "mern-ecs-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb" {
  name   = "mern-alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds" {
  name   = "mern-rds-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs.id]
  }
}

# IAM Role for ECS
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}



resource "aws_launch_template" "frontend" {
  name_prefix   = "mern-frontend"
  image_id      = data.aws_ami.ubuntu.id # Use a dynamically fetched AMI
  instance_type = "t3.micro"

  monitoring {
    enabled = true
  }

  user_data = base64encode(<<-EOF
                #!/bin/bash
                sudo apt update
                sudo apt install -y nodejs npm
                git clone https://github.com/your/frontend-repo.git
                cd frontend-repo
                npm install
                npm run build
                npm start
                EOF
  )
}


resource "aws_autoscaling_group" "frontend" {
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2
  vpc_zone_identifier = aws_subnet.public[*].id

  launch_template {
    id      = aws_launch_template.frontend.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "mern-frontend-instance"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "frontend_scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.frontend.name
}

resource "aws_autoscaling_policy" "frontend_scale_down" {
  name                   = "scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.frontend.name
}
