output "consul_gui" {
  value = "http://${aws_instance.consul-server.public_ip}:8500"
}


output "ecs_server_public_ip" {
  value = aws_instance.ecs-server.public_ip
}

output "ecs_server_2-public_ip" {
  value = aws_instance.ecs-server2.public_ip
}