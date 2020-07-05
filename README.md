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
* http-server: 3 Instances\
Each instance of the server and client corresponds with an ECS task that was created as part of your Terraform apply. 

```
Give an example
```

### And coding style tests

Explain what these tests test and why

```
Give an example
```

## Deployment

Add additional notes about how to deploy this on a live system

## Built With

* [Dropwizard](http://www.dropwizard.io/1.0.2/docs/) - The web framework used
* [Maven](https://maven.apache.org/) - Dependency Management
* [ROME](https://rometools.github.io/rome/) - Used to generate RSS Feeds

## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/your/project/tags). 

## Authors

* **Billie Thompson** - *Initial work* - [PurpleBooth](https://github.com/PurpleBooth)

See also the list of [contributors](https://github.com/your/project/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Hat tip to anyone whose code was used
* Inspiration
* etc
