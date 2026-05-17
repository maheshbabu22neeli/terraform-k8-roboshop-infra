variable "project" {
  default = "roboshop"
}

variable "environment" {
  default = "dev"
}

variable "zone_id" {
  default = "Z013175831RO1NWFBESW7"
}

variable "domain_name" {
  default = "neeli.online"
}

variable "jenkins" {
  default = false
}

variable "jenkins_agent" {
  default = false
}

variable "sonar" {
  default = false
}

variable "github_runner" {
  default = true
}