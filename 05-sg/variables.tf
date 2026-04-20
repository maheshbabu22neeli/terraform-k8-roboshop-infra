variable "project" {
  type    = string
  default = "roboshop"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "sg_names" {
  type = list(string)
  default = [
    # Databases
    "mongodb", "redis", "mysql", "rabbitmq",
    # Frontend ALB
    "ingress_alb",
    # Bastion
    "bastion",
    # Open VPN
    "openvpn",
    # EKS
    "eks_control_plane", "eks_node"
  ]
}