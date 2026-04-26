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

````

### Create Databases
```shell
Now, 
1. Create Namespace
kubectl apply -f 25-custom-eks/app/00-namespace/namespace.yaml

2. Create Storage Class
kubectl apply -f 25-custom-eks/app/01-storage-class/storage-class.yaml

3. Create remaining databases
3.1 Create Mongo DB
kubectl apply -f 25-custom-eks/app/02-mongodb/mongodb.yaml

````

### Create Backend
```shell

4.0 Create Debug
kubectl apply -f manifest.yaml

4.1 Create Catalogue
helm upgrade --install catalogue .

4.2 Create User
helm upgrade --install user .

4.3 Create Cart
helm upgrade --installc cart .

4.4 Create Shipping
helm upgrade --install shipping .

4.5 Create Payment
helm upgrade --install payment .

```

### Create Frontend using Ingress using ServiceAccount
1. We need OIDC (OpenIDConnect) provider to be enabled in the cluster to use IAM roles for Service Accounts (IRSA) in EKS.
2. Create IAM role and attach permissions to the role
3. Create Service Account
4. Install AWS Load Balancer Controller drivers using Helm and specify the Service Account created in the previous step
5. Run POD with the Service Account
6. This allows the Service Account to assume the IAM role and access AWS resources securely without needing to manage long-term credentials.

#### Create OIDC provider
```shell
3.91.206.107 | 10.0.1.25 | t3.micro | null
[ ec2-user@ip-10-0-1-25 ~ ]$ curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v3.2.1/docs/install/iam_policy.json
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100  8955  100  8955    0     0  91377      0 --:--:-- --:--:-- --:--:-- 92319
```

#### Create IAM Policy
```shell
3.91.206.107 | 10.0.1.25 | t3.micro | null
[ ec2-user@ip-10-0-1-25 ~ ]$ aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam-policy.json
{
    "Policy": {
        "PolicyName": "AWSLoadBalancerControllerIAMPolicy",
        "PolicyId": "ANPAS7GGOGYBGOYINQJTU",
        "Arn": "arn:aws:iam::<AWS_ACCOUNT>:policy/AWSLoadBalancerControllerIAMPolicy",
        "Path": "/",
        "DefaultVersionId": "v1",
        "AttachmentCount": 0,
        "PermissionsBoundaryUsageCount": 0,
        "IsAttachable": true,
        "CreateDate": "2026-04-26T07:37:09+00:00",
        "UpdateDate": "2026-04-26T07:37:09+00:00"
    }
}
```

#### Create Service Account
```shell
[ ec2-user@ip-10-0-1-25 ~ ]$ eksctl create iamserviceaccount \
  --cluster=roboshop-dev \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --attach-policy-arn=arn:aws:iam::<AWS_ACCOUNT>:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --region us-east-1 \
  --approve
2026-04-26 07:40:40 [ℹ]  1 iamserviceaccount (kube-system/aws-load-balancer-controller) was included (based on the include/exclude rules)
2026-04-26 07:40:40 [!]  metadata of serviceaccounts that exist in Kubernetes will be updated, as --override-existing-serviceaccounts was set
2026-04-26 07:40:40 [ℹ]  1 task: {
    2 sequential sub-tasks: {
        create IAM role for serviceaccount "kube-system/aws-load-balancer-controller",
        create serviceaccount "kube-system/aws-load-balancer-controller",
    } }2026-04-26 07:40:40 [ℹ]  building iamserviceaccount stack "eksctl-roboshop-dev-addon-iamserviceaccount-kube-system-aws-load-balancer-controller"
2026-04-26 07:40:40 [ℹ]  deploying stack "eksctl-roboshop-dev-addon-iamserviceaccount-kube-system-aws-load-balancer-controller"
2026-04-26 07:40:40 [ℹ]  waiting for CloudFormation stack "eksctl-roboshop-dev-addon-iamserviceaccount-kube-system-aws-load-balancer-controller"
2026-04-26 07:41:10 [ℹ]  waiting for CloudFormation stack "eksctl-roboshop-dev-addon-iamserviceaccount-kube-system-aws-load-balancer-controller"
2026-04-26 07:41:10 [ℹ]  created serviceaccount "kube-system/aws-load-balancer-controller"

```
#### Create AWS Load Balancer Controller using Helm
```shell
3.91.206.107 | 10.0.1.25 | t3.micro | null
[ ec2-user@ip-10-0-1-25 ~ ]$ helm repo add eks https://aws.github.io/eks-charts
"eks" has been added to your repositories

3.91.206.107 | 10.0.1.25 | t3.micro | null
[ ec2-user@ip-10-0-1-25 ~ ]$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "aws-ebs-csi-driver" chart repository
...Successfully got an update from the "eks" chart repository
Update Complete. ⎈Happy Helming!⎈

3.91.206.107 | 10.0.1.25 | t3.micro | null
[ ec2-user@ip-10-0-1-25 ~ ]$ helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=roboshop-dev \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
NAME: aws-load-balancer-controller
LAST DEPLOYED: Sun Apr 26 07:46:10 2026
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
AWS Load Balancer controller installed!
```
