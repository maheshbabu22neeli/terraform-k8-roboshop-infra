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

## 20-rds
- This module will create the RDS instance for MySql database.
- We are using the K8 RDS module `source = "terraform-aws-modules/rds/aws"` to create RDS instance.
- Once MSQL RDS Created, we have to add the data to the database. 
- To do that we have to connect to the RDS instance using the EC2 bastion server.
```shell
Firstly transfer all the data files from Local to Bastion Server
> scp app-user.sql master-data.sql ec2-user@3.91.206.107:/tmp

Secondly, go to bastion and run the below command to connect to RDS instance and load the data to MySql database
Install mysql client in bastion server
sudo dnf install mysql -y
mysql -h roboshop-dev.c2ncquyas938.us-east-1.rds.amazonaws.com -u root -pRoboShop#1234 < /tmp/app-user.sql
mysql -h roboshop-dev.c2ncquyas938.us-east-1.rds.amazonaws.com -u root -pRoboShop#1234 < /tmp/master-data.sql

$ mysql -h roboshop-dev.c2ncquyas938.us-east-1.rds.amazonaws.com -u root -pRoboShop#1234
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 131
Server version: 8.0.45 Source distribution

Copyright (c) 2000, 2026, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| cities             |
| information_schema |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
5 rows in set (0.08 sec)

mysql> use cities;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> show tables;
+------------------+
| Tables_in_cities |
+------------------+
| cities           |
| codes            |
+------------------+
2 rows in set (0.09 sec)

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
