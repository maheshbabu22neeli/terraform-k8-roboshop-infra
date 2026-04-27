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
> scp app-user.sql master-data.sql ec2-user@13.220.144.75:/tmp

Secondly, go to bastion and run the below command to connect to RDS instance and load the data to MySql database
Install mysql client in bastion server
sudo dnf install mysql -y
mysql -h roboshop-dev.c2ncquyas938.us-east-1.rds.amazonaws.com -u root -pRoboShop#1234 < app-user.sql
mysql -h roboshop-dev.c2ncquyas938.us-east-1.rds.amazonaws.com -u root -pRoboShop#1234 < master-data.sql

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

Now try to load database prerequisites data to MySql service using the below command
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
kubectl apply -f 25-custom-eks/app/02-databases/mongodb/manifest.yaml
kubectl apply -f 25-custom-eks/app/02-databases/redis/manifest.yaml
kubectl apply -f 25-custom-eks/app/02-databases/rabbitmq/manifest.yaml

````

### Create Backend
```shell
Go to
cd 25-custom-eks/app/03-backend

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

### Create Frontend using Ingress and ServiceAccount
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
  --attach-policy-arn=arn:aws:iam::204427113986:policy/AWSLoadBalancerControllerIAMPolicy \
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


Command to delete any existing ServiceAccount
eksctl delete iamserviceaccount \
  --cluster=roboshop-dev \
  --namespace=kube-system \
  --name=aws-load-balancer-controller
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

#### Run Frontend POD
```shell
$ helm upgrade --install frontend .
Release "frontend" does not exist. Installing it now.
NAME: frontend
LAST DEPLOYED: Sun Apr 26 08:13:48 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
``````

#### Create record in route53
```shell
Go to loadbalancer and fetch the DNS name and create a record in route53 with the same DNS name

And hit the given url in browser to access the frontend application
https://roboshop-dev.neeli.online/
```
![application_with_ingress.png](images/application_with_ingress.png)


### Create AWS Load balancer using Gateway
1. In the above Ingress control way of creation to ALB is a bit tricky and Engineers has to maintain all the k8 admin tasks. 
2. In order to overcome the engineer burden and to have clear roles between admin and engineer, they have introduced Gateway controller.
3. This can be achieved by
#### Admin Tasks
- Gateway Class                 -> tells which load balancer to use
- Load Balancer Configuration   -> Internal/Intenet
- Gateway Configuration         -> tells about listener

#### Engineer Tasks
- TargetGroup Configuration
- HttpRoute

#### Steps to achieve Gateway Controller
```shell
1. Delete existing Ingress from the K8
   Open k9s toll and select roboshop namespace
   Now, do a get using shift+: and type ingress, it will show ingress details.
   Click on ctrl+d to delete
   
2. Uninstall Drivers
   helm uninstall aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system
   
3. Install gateway-api new Kind standards
    kubectl apply --server-side=true -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.0/standard-install.yaml
    
4. Install AWS Load Balancer Controller
  VPC_ID=$(aws ssm get-parameter --name /roboshop-dev/vpc_id \
  --region us-east-1 --query Parameter.Value --output text)
  
  helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=roboshop-dev \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=us-east-1 \
  --set vpcId=$VPC_ID \
  --set controllerConfig.featureGates.ALBGatewayAPI=true \
  --set controllerConfig.featureGates.NLBGatewayAPI=true

  kubectl rollout status deployment aws-load-balancer-controller -n kube-system
  
  kubectl get pods -n kube-system | grep aws-load-balancer
  
5. Now configure frontend application using gatway
3.91.206.107 | 10.0.1.25 | t3.micro | https://github.com/maheshbabu22neeli/terraform-k8-roboshop-infra.git
[ ec2-user@ip-10-0-1-25 ~/terraform-k8-roboshop-infra/25-custom-eks/app/05-frontend-gateway ]$ kubectl apply -f 01-gateway-class.yaml
gatewayclass.gateway.networking.k8s.io/roboshop-aws-alb created

3.91.206.107 | 10.0.1.25 | t3.micro | https://github.com/maheshbabu22neeli/terraform-k8-roboshop-infra.git
[ ec2-user@ip-10-0-1-25 ~/terraform-k8-roboshop-infra/25-custom-eks/app/05-frontend-gateway ]$ kubectl apply -f 02-loadbalancerconfiguration.yaml
loadbalancerconfiguration.gateway.k8s.aws/roboshop-aws-alb-config created

3.91.206.107 | 10.0.1.25 | t3.micro | https://github.com/maheshbabu22neeli/terraform-k8-roboshop-infra.git
[ ec2-user@ip-10-0-1-25 ~/terraform-k8-roboshop-infra/25-custom-eks/app/05-frontend-gateway ]$ kubectl apply -f 03-gateway.yaml
gateway.gateway.networking.k8s.io/roboshop-gateway created

3.91.206.107 | 10.0.1.25 | t3.micro | https://github.com/maheshbabu22neeli/terraform-k8-roboshop-infra.git
[ ec2-user@ip-10-0-1-25 ~/terraform-k8-roboshop-infra/25-custom-eks/app/05-frontend-gateway ]$ kubectl apply -f 04-frontend.yaml
targetgroupconfiguration.gateway.k8s.aws/frontend-tgconfig created
httproute.gateway.networking.k8s.io/frontend-route created

Create alias record in Rout53 and access the application using "https://roboshop-dev.neeli.online/"
```
![application_with_gateway.png](images/application_with_gateway.png)

#### Drawbacks from above implementations
- Why kubernetes is creating all the AWS ALB, Listener, Rules, and TargetGroup
- These can be created easily by using terraform
- We can have more control on our side part of work


### Create Frontend by AWS terraform 
1. Create ALB
2. Create Listener
3. Create Rule
4. Create TargetGroup
5. Then just add TargetGroupBinding to attach pods

Before that we are cleaning all the resources created from above gateway approach
```shell
 1  13/01/26 18:30:51 sudo dnf update -y
    2  13/01/26 18:30:51 sudo dnf update -y
    3  13/01/26 18:37:26 sudo init 0
    4  27/04/26 10:48:12 clear
    5  27/04/26 10:49:47 aws eks update-kubeconfig --name reoboshop-dev --region us-east-1
    6  27/04/26 10:49:59 aws configure
    7  27/04/26 10:50:28 aws eks update-kubeconfig --name reoboshop-dev --region us-east-1
    8  27/04/26 10:50:42 aws eks update-kubeconfig --name roboshop-dev --region us-east-1
    9  27/04/26 10:51:44 git clone https://github.com/maheshbabu22neeli/terraform-k8-roboshop-infra.git
   10  27/04/26 10:51:52 cd terraform-k8-roboshop-infra/
   11  27/04/26 10:51:58 cd 25-custom-eks/
   12  27/04/26 10:52:02 cd app
   13  27/04/26 10:52:05 ls -la
   14  27/04/26 10:52:09 cd 00-namespace/
   15  27/04/26 10:52:26 kubectl apply -f namespace.yaml
   16  27/04/26 10:53:14 helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
   17  27/04/26 10:53:20 helm repo update
   18  27/04/26 10:53:28 helm upgrade --install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver --namespace kube-system
   19  27/04/26 10:54:48 cd ..
   20  27/04/26 10:55:00 cd 01-storage-class/
   21  27/04/26 10:55:10 kubectl apply -f ebs-storage-class.yaml
   22  27/04/26 10:55:19 cd ..
   23  27/04/26 10:56:19 cd ../..
   24  27/04/26 10:56:24 kubectl apply -f 25-custom-eks/app/02-databases/mongodb.yaml
   25  27/04/26 10:57:33 kubectl apply -f 25-custom-eks/app/02-databases/mongodb/manifest.yaml
   26  27/04/26 10:57:42 kubectl apply -f 25-custom-eks/app/02-databases/redis/manifest.yaml
   27  27/04/26 10:57:49 kubectl apply -f 25-custom-eks/app/02-databases/rabbitmq/manifest.yaml
   28  27/04/26 11:00:40 cd 25-custom-eks/app/03-backend
   29  27/04/26 11:00:47 clear
   30  27/04/26 11:00:54 cd debug/
   31  27/04/26 11:01:02 kubectl apply -f manifest.yaml
   32  27/04/26 11:01:06 cd ..
   33  27/04/26 11:01:09 cd catalogue/
   34  27/04/26 11:01:17 helm upgrade --install catalogue .
   35  27/04/26 11:01:24 cd ../user/
   36  27/04/26 11:01:33 helm upgrade --install user .
   37  27/04/26 11:01:38 cd ../cart/
   38  27/04/26 11:01:46 helm upgrade --installc cart .
   39  27/04/26 11:01:52 cd ../shipping/
   40  27/04/26 11:01:58 helm upgrade --install shipping .
   41  27/04/26 11:02:04 cd ../payment/
   42  27/04/26 11:02:10 helm upgrade --install payment .
   43  27/04/26 11:02:15 clear
   44  27/04/26 11:03:25 cd ../
   45  27/04/26 11:03:28 cd ..
   46  27/04/26 11:03:35 ls
   47  27/04/26 11:03:41 cd 20-rds/
   48  27/04/26 11:03:43 ls -la
   49  27/04/26 11:03:53 cd data-files/
   50  27/04/26 11:03:55 ls -la
   51  27/04/26 11:05:17 sudo dnf install mysql -y
   52  27/04/26 11:06:11 ls
   53  27/04/26 11:06:36 mysql -h roboshop-dev.c2ncquyas938.us-east-1.rds.amazonaws.com -u root -pRoboShop#1234 < app-user.sql
   54  27/04/26 11:06:47 mysql -h roboshop-dev.c2ncquyas938.us-east-1.rds.amazonaws.com -u root -pRoboShop#1234 < master-data.sql
   55  27/04/26 11:15:24 cd
   56  27/04/26 11:15:36  curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v3.2.1/docs/install/iam_policy.json
   57  27/04/26 11:15:51 aws iam create-policy     --policy-name AWSLoadBalancerControllerIAMPolicy     --policy-document file://iam-policy.json
   58  27/04/26 11:16:44 eksctl create iamserviceaccount   --cluster=roboshop-dev   --namespace=kube-system   --name=aws-load-balancer-controller   --attach-policy-arn=arn:aws:iam::204427113986:policy/AWSLoadBalancerControllerIAMPolicy   --override-existing-serviceaccounts   --region us-east-1   --approve
   59  27/04/26 11:17:49 eksctl create iamserviceaccount   --cluster=roboshop-dev   --namespace=kube-system   --name=aws-load-balancer-controller
   60  27/04/26 11:18:07 eksctl delete iamserviceaccount   --cluster=roboshop-dev   --namespace=kube-system   --name=aws-load-balancer-controller
   61  27/04/26 11:20:14 eksctl create iamserviceaccount   --cluster=roboshop-dev   --namespace=kube-system   --name=aws-load-balancer-controller   --attach-policy-arn=arn:aws:iam::204427113986:policy/AWSLoadBalancerControllerIAMPolicy   --override-existing-serviceaccounts   --region us-east-1   --approve
   62  27/04/26 11:27:46 helm repo add eks https://aws.github.io/eks-charts
   63  27/04/26 11:27:57 helm repo update
   64  27/04/26 11:28:12 helm install aws-load-balancer-controller eks/aws-load-balancer-controller   -n kube-system   --set clusterName=roboshop-dev   --set serviceAccount.create=false   --set serviceAccount.name=aws-load-balancer-controller
   65  27/04/26 11:35:01 clear
   66  27/04/26 11:35:04 history



```