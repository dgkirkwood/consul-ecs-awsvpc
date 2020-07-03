#Creating consul configuration for the consul agents and service registrations. Can be changed if you want to test another application

resource "local_file" "http-server" {
    content     = templatefile("templates/http-server.json.template", {server_service_name="http-server", server_service_port=80})
    filename = "configs/server.hcl"
}

resource "local_file" "http-client" {
    content     = templatefile("templates/http-client.json.template", {client_service_name="http-client", client_service_port=8080, upstream_name="http-server", upstream_port=8085})
    filename = "configs/client.hcl"
}

resource "local_file" "consul-agent-config" {
    content     = templatefile("templates/consul-agent-config.json.template", {consul_dc=var.aws_region})
    filename = "configs/config.json"
}