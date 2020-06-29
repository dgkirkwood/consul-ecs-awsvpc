# Allow EC2 instances to receive HTTP/HTTPS/SSH traffic IN and any traffic OUT
resource "aws_security_group" "consul" {
  name_prefix = "${var.cluster_name}_consul"
  description = "Security group for Consul server"
  vpc_id      = module.vpc.vpc_id
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = var.cluster_name
  }
}


resource "aws_security_group_rule" "allow_server_rpc_inbound" {
  type        = "ingress"
  from_port   = 8300
  to_port     = 8300
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.consul.id
}

resource "aws_security_group_rule" "allow_cli_rpc_inbound" {
  type        = "ingress"
  from_port   = 8400
  to_port     = 8400
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.consul.id
}

resource "aws_security_group_rule" "allow_serf_lan_tcp_inbound" {
  type        = "ingress"
  from_port   = 8301
  to_port     = 8301
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.consul.id
}

resource "aws_security_group_rule" "allow_serf_lan_udp_inbound" {
  type        = "ingress"
  from_port   = 8301
  to_port     = 8301
  protocol    = "udp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.consul.id
}

resource "aws_security_group_rule" "allow_http_api_inbound" {
  type        = "ingress"
  from_port   = 8500
  to_port     = 8500
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.consul.id
}

resource "aws_security_group_rule" "allow_dns_tcp_inbound" {
  type        = "ingress"
  from_port   = 8600
  to_port     = 8600
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.consul.id
}

resource "aws_security_group_rule" "allow_dns_udp_inbound" {
  type        = "ingress"
  from_port   = 8600
  to_port     = 8600
  protocol    = "udp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.consul.id
}

resource "aws_security_group_rule" "allow_grpc_inbound" {
  type        = "ingress"
  from_port   = 8502
  to_port     = 8502
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.consul.id
}




