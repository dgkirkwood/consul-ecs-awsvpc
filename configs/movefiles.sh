#!/bin/sh
sudo mkdir /ecs
sudo mkdir /ecs/consul-agent
sudo mkdir /ecs/envoy-s
sudo mkdir /ecs/envoy-c
sudo mv ~/config.json /ecs/consul-agent
sudo mv ~/server.hcl /ecs/envoy-s
sudo mv ~/client.hcl /ecs/envoy-c