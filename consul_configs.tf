resource "local_file" "http-server" {
    content     = templatefile("templates/http-server.json.template", {server_service_name="http-server", server_service_port=80})
    filename = "configs/server.hcl"
}

resource "local_file" "http-client" {
    content     = templatefile("templates/http-client.json.template", {client_service_name="http-client", client_service_port=8080, upstream_name="http-server", upstream_port=8085})
    filename = "configs/client.hcl"
}

resource "local_file" "consul-agent-config" {
    content     = templatefile("templates/consul-agent-config.json.template", {consul_dc="aws-ap-southeast-2"})
    filename = "configs/config.json"
}