variable "project" {
  default = "roboshop"
}

variable "environment" {
  default = "dev"
}

variable "bastion_policy_arns" {
  description = "List of IAM Policy ARNs to be attached to the role"
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]
}