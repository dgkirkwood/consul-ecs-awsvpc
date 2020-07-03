provider "aws" {
    region = var.aws_region
}



#Find Ubuntu AMI for hosting Consul server
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


#Create EC2 instance to host consul server
#Default size is T2.micro, fine for demo
resource "aws_instance" "consul-server" {
    ami           = data.aws_ami.ubuntu.id
    instance_type = var.consul_instance_size

    network_interface {
        network_interface_id = aws_network_interface.consul-server.id
        device_index         = 0
    }
    #User data field to grab Consul binary, create necessary directories and start agent with config
    #Relies on the file provisioner in the same resource
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
    #Copy the config file to the server
    provisioner "file" {
      source      = "configs/serverconfig.hcl"
      destination = "/home/ubuntu/serverconfig.hcl"
      connection {
        type     = "ssh"
        user     = "ubuntu"
        private_key = file(var.private_key_path)
        host = aws_instance.consul-server.public_ip
  }
    }

    #Must correspond to an existing EC2 key name 
    key_name = var.aws_ec2_key

    tags = {
        Name = "${var.cluster_name}-consul-server"
    }
}


#Find AMI optimised for ECS
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



#Two ECS servers are created to allow enough ENI interfaces for testing our application
#Default instance size is t2.small - more ENIs than the t2.micro
resource "aws_instance" "ecs-server" {
    ami           = data.aws_ami.ecs.id
    instance_type = var.ecs_instance_size

    network_interface {
        network_interface_id = aws_network_interface.ecs-server.id
        device_index         = 0
    }

    key_name = var.aws_ec2_key
    iam_instance_profile = aws_iam_instance_profile.ec2_iam_instance_profile.name

    #User data string required to populate ENV vars which will auto register this instance with our ECS cluster
    user_data = <<EOF
      #!/bin/bash
      echo ECS_CLUSTER=${var.cluster_name} >> /etc/ecs/ecs.config
      echo ECS_INSTANCE_ATTRIBUTES={\"purchase-option\":\"ondemand\"} >> /etc/ecs/ecs.config


      EOF

    #Provisioner to copy across config files which will be presented as volumes for containers managed by ECS
    provisioner "file" {
      source      = "configs/"
      destination = "/home/ec2-user"
      connection {
        type     = "ssh"
        user     = "ec2-user"
        private_key = file(var.private_key_path)
        host = aws_instance.ecs-server.public_ip
      }

    }

    #Provisioner to execute script placing files in the correct directories to be consumed by containers
    provisioner "remote-exec" {
      inline = [
        "chmod +x /home/ec2-user/movefiles.sh",
        "/home/ec2-user/movefiles.sh"
      ]
      connection {
        type     = "ssh"
        user     = "ec2-user"
        private_key = file(var.private_key_path)
        host = aws_instance.ecs-server.public_ip
  }
    }

    tags = {
        Name = "${var.cluster_name}-ecs-server"
    }
    #This will wait for the templated config files to be created before executing to ensure they are available for upload
    depends_on = [local_file.consul-agent-config]
}

#Second ECS server for ENI availability
resource "aws_instance" "ecs-server2" {
    ami           = data.aws_ami.ecs.id
    instance_type = var.ecs_instance_size

    network_interface {
        network_interface_id = aws_network_interface.ecs-server2.id
        device_index         = 0
    }

    key_name = var.aws_ec2_key
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
        private_key = file(var.private_key_path)
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
        private_key = file(var.private_key_path)
        host = aws_instance.ecs-server2.public_ip
  }
    }

    tags = {
        Name = "${var.cluster_name}-ecs-server"
    }
    depends_on = [local_file.consul-agent-config]
}





