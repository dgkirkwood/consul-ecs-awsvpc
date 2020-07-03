variable "cluster_name" {
  type = string
  description = "A unique name applied to resources including the ECS cluster"
}

variable "aws_region" {
    type = string
}

variable "aws_az" {
    type = string
    description = "The AZ to host your ECS cluster"
} 

variable "consul_instance_size" {
    type = string
    default = "t2.micro"
}

variable "ecs_instance_size" {
    type = string
    default = "t2.small"
}

variable "aws_ec2_key" {
    type = string
    description = "EC2 key name that matches an available key already in AWS. You must have the corresponding private key to access machines"
}

#Must correspond to the private key for your EC2 key described above
variable "private_key_path" {
    type = string
    description = "The private key corresponding with your AWS Ec2 key. Used to upload files and do remote exec."
}
