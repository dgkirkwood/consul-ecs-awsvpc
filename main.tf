provider "aws" {
    region = "ap-southeast-2"
}

variable "cluster_name" {
  type = string
  default  = "dk-ecs-vpc"
}


module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "VPC of cluster ${var.cluster_name}"
  cidr = "10.0.0.0/16"

  azs = ["ap-southeast-2a"]
  public_subnets = ["10.0.101.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false
  create_vpc         = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}


data "aws_ami" "ubuntu" {
    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"] # Canonical
}


resource "aws_network_interface" "consul-server" {
  subnet_id   = module.vpc.public_subnets[0]
  private_ips = ["10.0.101.100"]
  security_groups = [aws_security_group.consul.id, aws_security_group.sg_for_ec2_instances.id]

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_instance" "consul-server" {
    ami           = data.aws_ami.ubuntu.id
    instance_type = "t2.micro"

    network_interface {
        network_interface_id = aws_network_interface.consul-server.id
        device_index         = 0
    }
    user_data = <<EOF
#!/bin/bash
wget https://releases.hashicorp.com/consul/1.8.0/consul_1.8.0_linux_amd64.zip
sudo apt install unzip
unzip consul_1.8.0_linux_amd64.zip
sudo mv consul /usr/local/bin/
sudo mkdir /opt/consul/
sudo mkdir /opt/consul/config
sudo mkdir /opt/consul/data
sudo mv /home/ubuntu/serverconfig.hcl /opt/consul/config
sudo consul agent -config-file=/opt/consul/config/serverconfig.hcl
EOF

    provisioner "file" {
      source      = "configs/serverconfig.hcl"
      destination = "/home/ubuntu/serverconfig.hcl"
      connection {
        type     = "ssh"
        user     = "ubuntu"
        private_key = file("/Users/dan/.ssh/aws-ec2")
        host = aws_instance.consul-server.public_ip
  }
    }


    key_name = "dk-ec2-key"

    tags = {
        Name = "${var.cluster_name}-consul-server"
    }
}



data "aws_ami" "ecs" {
  most_recent = true

  filter {
    name = "name"
    values = [
    "amzn2-ami-ecs-*"]
  }

  filter {
    name = "virtualization-type"
    values = [
    "hvm"]
  }

  owners = [
    "amazon"
  ]
}

resource "aws_network_interface" "ecs-server" {
  subnet_id   = module.vpc.public_subnets[0]
  private_ips = ["10.0.101.150"]
  security_groups = [aws_security_group.sg_for_ec2_instances.id]

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_network_interface" "ecs-server2" {
  subnet_id   = module.vpc.public_subnets[0]
  private_ips = ["10.0.101.155"]
  security_groups = [aws_security_group.sg_for_ec2_instances.id]

  tags = {
    Name = "primary_network_interface"
  }
}

resource "aws_instance" "ecs-server" {
    ami           = data.aws_ami.ecs.id
    instance_type = "t2.small"

    network_interface {
        network_interface_id = aws_network_interface.ecs-server.id
        device_index         = 0
    }

    key_name = "dk-ec2-key"
    iam_instance_profile = aws_iam_instance_profile.ec2_iam_instance_profile.name
    user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${var.cluster_name} >> /etc/ecs/ecs.config
echo ECS_INSTANCE_ATTRIBUTES={\"purchase-option\":\"ondemand\"} >> /etc/ecs/ecs.config


EOF

    provisioner "file" {
      source      = "configs/"
      destination = "/home/ec2-user"
      connection {
        type     = "ssh"
        user     = "ec2-user"
        private_key = file("/Users/dan/.ssh/aws-ec2")
        host = aws_instance.ecs-server.public_ip
  }

    }

    provisioner "remote-exec" {
      inline = [
        "chmod +x /home/ec2-user/movefiles.sh",
        "/home/ec2-user/movefiles.sh"
      ]
      connection {
        type     = "ssh"
        user     = "ec2-user"
        private_key = file("/Users/dan/.ssh/aws-ec2")
        host = aws_instance.ecs-server.public_ip
  }
    }

    tags = {
        Name = "${var.cluster_name}-ecs-server"
    }
    depends_on = [local_file.consul-agent-config]
}

resource "aws_instance" "ecs-server2" {
    ami           = data.aws_ami.ecs.id
    instance_type = "t2.small"

    network_interface {
        network_interface_id = aws_network_interface.ecs-server2.id
        device_index         = 0
    }

    key_name = "dk-ec2-key"
    iam_instance_profile = aws_iam_instance_profile.ec2_iam_instance_profile.name
    user_data = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${var.cluster_name} >> /etc/ecs/ecs.config
echo ECS_INSTANCE_ATTRIBUTES={\"purchase-option\":\"ondemand\"} >> /etc/ecs/ecs.config


EOF

    provisioner "file" {
      source      = "configs/"
      destination = "/home/ec2-user"
      connection {
        type     = "ssh"
        user     = "ec2-user"
        private_key = file("/Users/dan/.ssh/aws-ec2")
        host = aws_instance.ecs-server2.public_ip
  }

    }

    provisioner "remote-exec" {
      inline = [
        "chmod +x /home/ec2-user/movefiles.sh",
        "/home/ec2-user/movefiles.sh"
      ]
      connection {
        type     = "ssh"
        user     = "ec2-user"
        private_key = file("/Users/dan/.ssh/aws-ec2")
        host = aws_instance.ecs-server2.public_ip
  }
    }

    tags = {
        Name = "${var.cluster_name}-ecs-server"
    }
    depends_on = [local_file.consul-agent-config]
}


# Create an IAM role for the ECS EC2 instances.
data "aws_iam_policy_document" "ecs_role_definition" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      identifiers = [
        "ec2.amazonaws.com",
        "ecs-tasks.amazonaws.com"
      ]
      type = "Service"
    }
  }
}
resource "aws_iam_role" "ecs_role" {
  name_prefix        = "${var.cluster_name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_role_definition.json

  # Allows the role to be deleted and reacreated (when needed)
  force_detach_policies = true
}

# Create an IAM policy which allows the ECS agent to function inside EC2 instances
data "aws_iam_policy_document" "ecs_instance_role_policy_doc" {
  statement {
    actions = [
      # Requirements for ECS agent
      "ecs:CreateCluster",
      "ecs:DeregisterContainerInstance",
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:RegisterContainerInstance",
      "ecs:StartTelemetrySession",
      "ecs:Submit*",
      "ecs:StartTask",

      # Requirements for EC2 instances within the cluster to be able to pull ECR Docker images
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",

      # Allow EC2 instances to write to CloudWatch logs
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "*",
    ]
  }
}
resource "aws_iam_policy" "ecs_role_permissions" {
  name_prefix = "${var.cluster_name}-ecs-policy"
  description = "These policies allow the ECS instances to do certain actions like pull images from ECR"
  path        = "/"
  policy      = data.aws_iam_policy_document.ecs_instance_role_policy_doc.json
}

# Attach the ECS agent IAM policy to the service Role that is assinged to each EC2 instance
resource "aws_iam_policy_attachment" "ecs_instance_role_policy_attachment" {
  name = "${var.cluster_name}-iam-policy-attachment"
  roles = [
    aws_iam_role.ecs_role.name
  ]
  policy_arn = aws_iam_policy.ecs_role_permissions.arn
}

# Allow EC2 instances to be launched using this role,
# allowing them to automatically gain the permissions that were present in this role
# (attached through policies to the Role)
resource "aws_iam_instance_profile" "ec2_iam_instance_profile" {
  name_prefix = var.cluster_name
  role        = aws_iam_role.ecs_role.name
}


resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.cluster_name
}
