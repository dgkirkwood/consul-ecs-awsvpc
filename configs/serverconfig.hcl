datacenter = "aws-ap-southeast-2"
data_dir = "/opt/consul/data"
server = true
ui = true
bootstrap_expect = 1
connect  {
        enabled = true
}
client_addr = "0.0.0.0"
ports {
    grpc = 8502
}