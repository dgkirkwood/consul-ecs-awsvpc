# Service Mesh with Consul on AWS Elastic Container Service (ECS)

This repo is an example pattern of setting up a service mesh with Consul as part of your ECS deployment. 
Using Consul in this case gives us an up-to-date service registry of our microservices in ECS with integrated health checks. 
Using Consul service mesh we can also provide automated mTLS between microservices, and ensure that all app connections are authorized. 

## Getting Started

This repository uses Terraform to create everything needed in the demo environment. The code requires a few variables (detailed below) and will instantiate a Consul server two microservices which will automatically register and become part of the mesh. 

### Prerequisites

* Ensure you have the [Terraform](https://www.terraform.io/downloads.html) binary installed on your local machine 
* You will need the appropriate credentials for Terraform to provision on AWS. [Instructions here](https://www.terraform.io/docs/providers/aws/index.html).
* You will need an EC2 key pair created on AWS as it is a required variable for provisioning your infrastructure. (Hint: you can do this with Terraform!) Ensure the private key is in a known local path as this is another required variable

### Terraform Variables

* An example variables file is included in the repo named variables.tfvars.example. Copy this file and rename it to terraform.tfvars
* Populate the variables, making sure that the Availability Zone you choose is valid for the region.
* Also ensure you choose appropriate size instances. The defaults are t2.micro for Consul and t2.small for the ECS servers.
* The reason t2.small is used is because it can provide more Elastic Network Interfaces (ENIs) which are assigned to the ECS tasks. 

### Creating the environment


1. Clone this repository to your local machine

2. Initialise the Terraform code with the following

```
terraform init
```

3. If the initiation is successful, run a Terraform plan to see the resources that will be created

```
terraform plan
```

4. If you are happy with the plan, apply the changes. 

```
terraform apply
```


## Connect to the environment

If step 4 of creating the environment colmpleted succesfully, you should have three output items on your CLI:
```
consul_gui = 
ecs_server_2-public_ip = 
ecs_server_public_ip = 
```

### Connect to Consul

Port 8500 of the Consul server is exposed for the GUI service linked above. 
Paste the link into a browser and you should see Consul running with three services registered
* Consul itself
* http-client: 1 Instance
* http-server: 3 Instances

\
Each instance of the server and client corresponds with an ECS task that was created as part of your Terraform apply.\
Explore the GUI to see the associated proxies and health checks on each service.

### Connect to the Client service

To show the functioning service mesh we need to connect to an ECS host running the client service. 
This is not necessarily deterministic, but try SSHing to either one of your ECS servers, using the IP address exposed as an output from Terraform. 

1. SSH to an ECS host

```
ssh -i /path/to/privatekey ec2-user@xx.xx.xx.xx
```
2. Inspect the docker containers running on the host
```
docker ps
```
You are looking for a container running the image tutum/curl:latest with a name like ecs-serviceMeshAppClient-17-client-ecb99b9194f7f4e2a901\
3. Once you find the container, execute a curl using the following commmand: 
```
docker exec -it <replace-me-with-client-container-name> curl 127.0.0.1:8085
```
You should see the following:
```
"hello world"
```
If you have, you have just demonstrated a working service mesh on ECS! To prove we are performing authorized connections, lets block connection between the client and the server, following the steps below.



### Test Consul intentions

1. Go back to the Consul GUI and click the Intentions top menu item
2. Click the blue 'Create' button
3. For source service select 'http-client' and for destination service select 'http-server'
4. Keep the default radio button selection on 'Deny'
5. Click 'Save'

\
You should see a green 'Success' message appear, and your intention listed on the intentions page.
6. Go back to your SSH session, and run the same docker exec command 
```
docker exec -it <replace-me-with-client-container-name> curl 127.0.0.1:8085
```
7. You should now get an error with an empty reply from the server. The service mesh proxies have stopped the connection as per your intention. 


## Spin down your environment

Terraform makes it very easy to get rid of this environment when we are done. Simply run: 
```
terraform destroy
```
Type yes to confirm and Terraform will remove all of your resources. 