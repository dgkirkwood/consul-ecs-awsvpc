resource "aws_ecs_task_definition" "server" {
  family = "serviceMeshAppServer"
  container_definitions = file("task-definitions/server.json")

  network_mode = "awsvpc"

  volume {
    name = "envoy-s"
    host_path = "/ecs/envoy-s"
  }
  volume {
    name = "consul"
    host_path = "/ecs/consul-agent"
  }
}

resource "aws_ecs_service" "http-server" {
  name = "${var.cluster_name}-http-server"
  cluster = aws_ecs_cluster.ecs_cluster.id
  desired_count = 3
  task_definition = "${aws_ecs_task_definition.server.family}:${max("${aws_ecs_task_definition.server.revision}", "${data.aws_ecs_task_definition.server.revision}")}"
  #task_definition = aws_ecs_task_definition.server.family
  network_configuration {
    security_groups = [aws_security_group.sg_for_ec2_instances.id]
    subnets         = [module.vpc.public_subnets[0]]
}
}

data "aws_ecs_task_definition" "server" {
  task_definition = aws_ecs_task_definition.server.family
  depends_on = [aws_ecs_task_definition.server]
}


resource "aws_ecs_task_definition" "client" {
  family = "serviceMeshAppClient"
  container_definitions = file("task-definitions/client.json")

  network_mode = "awsvpc"

  volume {
    name = "envoy-c"
    host_path = "/ecs/envoy-c"
  }
  volume {
    name = "consul"
    host_path = "/ecs/consul-agent"
  }
}

resource "aws_ecs_service" "http-client" {
  name = "${var.cluster_name}-http-client"
  cluster = aws_ecs_cluster.ecs_cluster.id
  desired_count = 1
  task_definition = "${aws_ecs_task_definition.client.family}:${max("${aws_ecs_task_definition.client.revision}", "${data.aws_ecs_task_definition.client.revision}")}"
  #task_definition = aws_ecs_task_definition.server.family
  network_configuration {
    security_groups = [aws_security_group.sg_for_ec2_instances.id]
    subnets         = [module.vpc.public_subnets[0]]
}
}

data "aws_ecs_task_definition" "client" {
  task_definition = aws_ecs_task_definition.client.family
  depends_on = [aws_ecs_task_definition.client]
}