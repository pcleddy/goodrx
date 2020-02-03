terraform {
  required_version = ">= 0.12, < 0.13"
}

resource "aws_launch_configuration" "goodrx_launch_configuration" {
  image_id        = "ami-02ccb28830b645a41" # AWS
  instance_type   = var.instance_type
  security_groups = [aws_security_group.goodrx_instance_security_group.id]
  user_data       = data.template_file.user_data.rendered
  #key_name        = "2020-02-03"

  lifecycle {
    create_before_destroy = true
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/files/user-data.sh")
  vars = {
    server_port = var.server_port
  }
}

resource "aws_autoscaling_group" "goodrx_autoscaling_group" {
  launch_configuration = aws_launch_configuration.goodrx_launch_configuration.name
  vpc_zone_identifier  = data.aws_subnet_ids.goodrx_subnet_ids.ids
  target_group_arns    = [aws_lb_target_group.goodrx_target_group.arn]
  health_check_type    = "ELB"

  min_size = 1
  max_size = 1

  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }
}

resource "aws_security_group" "goodrx_instance_security_group" {
  name = "goodrx-instance"
}

resource "aws_security_group_rule" "allow_server_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.goodrx_instance_security_group.id

  from_port   = var.server_port
  to_port     = var.server_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_lb" "goodrx_lb" {
  name               = var.cluster_name
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.goodrx_subnet_ids.ids
  security_groups    = [aws_security_group.goodrx_alb_security_group.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.goodrx_lb.arn
  port              = local.http_port
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_target_group" "goodrx_target_group" {
  name     = var.cluster_name
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "goodrx_lb_listener_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    field  = "path-pattern"
    values = ["*"]
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.goodrx_target_group.arn
  }
}

resource "aws_security_group" "goodrx_alb_security_group" {
  name = "${var.cluster_name}-instance"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.goodrx_alb_security_group.id

  from_port   = local.http_port
  to_port     = local.http_port
  protocol    = local.tcp_protocol
  cidr_blocks = local.all_ips
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.goodrx_alb_security_group.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = local.all_ips
}

locals {
  http_port    = 80
  any_port     = 0
  any_protocol = "-1"
  tcp_protocol = "tcp"
  all_ips      = ["0.0.0.0/0"]
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "goodrx_subnet_ids" {
  vpc_id = data.aws_vpc.default.id
}
