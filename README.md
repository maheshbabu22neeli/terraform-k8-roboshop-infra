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

## 25-custom-eks
- This module will create the EKS cluster using the "terraform-platform-aws-eks" module.
- This module contains all the necessary configurations for applications, namespace, databases, frontend, and backend.
- Before running custom-eks module, make sure you have already run bastion configuration.
- Bastion configuration will create all the necessary tools to connect and play with eks cluster
- After login to bastion server, run the below command to connect to EKS cluster
```shell
aws configure
aws eks update-kubeconfig --name roboshop-dev --region us-east-1
kubectl get nodes
```
Now try to create load database data to MySql service using the below command
```shell
Firstly we require statefulset, headless service, normal service, PV , PVC and Storage Class.
Secondsly, In order to do EBS dynamic provisioning, we need to create Storage Class and PV and PVC.
Finally, we can create the statefulset and services for MySql database.

To do all we need drviers called EBSDriver 

helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update
helm upgrade --install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver --namespace kube-system

drivers installed

Now, 
1. Create Namespace
kubectl apply -f 25-custom-eks/app/00-namespace/namespace.yaml

2. Create Storage Class
kubectl apply -f 25-custom-eks/app/01-storage-class/storage-class.yaml

3. Create remaining databases
3.1 Create Mongo DB
kubectl apply -f 25-custom-eks/app/02-mongodb/mongodb.yaml




```
