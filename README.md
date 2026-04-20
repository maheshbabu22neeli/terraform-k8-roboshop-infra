# terraform-k8-eks
This repo contains the terraform code to create AWS and K8 infrastructure

# Architecture
![terraform-k8-eks.svg](images/terraform-k8-eks.svg)


## VPC
- We are using the same VPC module `terraform-platform-aws-vpc` created as part of roboshop project for VM infrastructure.
- Module repository link: `https://github.com/maheshbabu22neeli/terraform-platform-aws-vpc.git`
- This module will create the below resources in AWS
  - VPC
  - Subnets (Public and Private)
  - Internet Gateway
  - NAT Gateway
  - Route Tables and Routes
```shell
Go to 00-aws-vpc directory and run the below command to create VPC

terraform init
terraform plan
terraform apply -auto-approve
```

## 05-sg
- This module will create the security groups for DB, EKS Control Plane, EKS Worker Nodes and ALB
- We are using the same SG module `terraform-platform-aws-sg` created as part of roboshop project for VM infrastructure.
- Module repository link: `https://github.com/maheshbabu22neeli/terraform-platform-aws-sg.git`
```shell
Go to 05-sg directory and run the below command to create security groups
terraform init
terraform plan
terraform apply -auto-approve
```

