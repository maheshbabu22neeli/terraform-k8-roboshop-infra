data "http" "my_public_ip_v4" {
  url = "https://ipv4.icanhazip.com"
}

data "aws_ssm_parameter" "bastion_sg_id" {
  name = "/${var.project}-${var.environment}/bastion_sg_id"
}

data "aws_ssm_parameter" "mongodb_sg_id" {
  name = "/${var.project}-${var.environment}/mongodb_sg_id"
}

data "aws_ssm_parameter" "redis_sg_id" {
  name = "/${var.project}-${var.environment}/redis_sg_id"
}

data "aws_ssm_parameter" "mysql_sg_id" {
  name = "/${var.project}-${var.environment}/mysql_sg_id"
}

data "aws_ssm_parameter" "rabbitmq_sg_id" {
  name = "/${var.project}-${var.environment}/rabbitmq_sg_id"
}

data "aws_ssm_parameter" "eks_node_sg_id" {
  name = "/${var.project}-${var.environment}/eks_node_sg_id"
}

data "aws_ssm_parameter" "ingress_alb_sg_id" {
  name = "/${var.project}-${var.environment}/ingress_alb_sg_id"
}

data "aws_ssm_parameter" "eks_control_plane_sg_id" {
  name = "/${var.project}-${var.environment}/eks_control_plane_sg_id"
}

data "aws_ssm_parameter" "openvpn_sg_id" {
  name = "/${var.project}-${var.environment}/openvpn_sg_id"
}
