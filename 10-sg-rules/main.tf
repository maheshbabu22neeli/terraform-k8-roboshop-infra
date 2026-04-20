// Bastion
resource "aws_security_group_rule" "bastion_internet" {
  type      = "ingress"
  from_port = 22
  to_port   = 22
  protocol  = "tcp"
  #cidr_blocks       = ["0.0.0.0/0"] # from internet
  security_group_id = local.bastion_sg_id
  cidr_blocks       = [local.my_ip]
}

// MongoDB
resource "aws_security_group_rule" "mongodb_bastion" {
  type      = "ingress"
  from_port = 22
  to_port   = 22
  protocol  = "tcp"
  // which means mongodb accepting connection from bastion
  security_group_id        = local.mongodb_sg_id
  source_security_group_id = local.bastion_sg_id
}

// Redis
resource "aws_security_group_rule" "redis_bastion" {
  type      = "ingress"
  from_port = 22
  to_port   = 22
  protocol  = "tcp"
  // which means redis accepting connection from bastion
  security_group_id        = local.redis_sg_id
  source_security_group_id = local.bastion_sg_id
}

// MySQL
resource "aws_security_group_rule" "mysql_bastion" {
  type      = "ingress"
  from_port = 22
  to_port   = 22
  protocol  = "tcp"
  // which means mysql accepting connection from bastion
  security_group_id        = local.mysql_sg_id
  source_security_group_id = local.bastion_sg_id
}

// RabbitMq
resource "aws_security_group_rule" "rabbitmq_bastion" {
  type      = "ingress"
  from_port = 22
  to_port   = 22
  protocol  = "tcp"
  // which means rabbitmq accepting connection from bastion
  security_group_id        = local.rabbitmq_sg_id
  source_security_group_id = local.bastion_sg_id
}

resource "aws_security_group_rule" "mysql_eks_node" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  // which means mysql accepting connection from eks_node
  security_group_id = local.mysql_sg_id
  source_security_group_id = local.eks_node_sg_id
}

resource "aws_security_group_rule" "ingress_alb_public" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  // which means ingress_alb accepting connection from public / internet
  security_group_id = local.ingress_alb_sg_id
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "eks_control_plane_bastion" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  // which means eks_control_plane accepting connection from bastion
  security_group_id = local.eks_control_plane_sg_id
  source_security_group_id = local.bastion_sg_id
}

resource "aws_security_group_rule" "eks_node_bastion" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  // which means eks_node accepting connection from bastion
  security_group_id = local.eks_node_sg_id
  source_security_group_id = local.bastion_sg_id
}

resource "aws_security_group_rule" "eks_control_plane_eks_node" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" # all traffic
  // which means eks_control_plane accepting connection from eks_node
  security_group_id = local.eks_control_plane_sg_id
  source_security_group_id = local.eks_node_sg_id
}

resource "aws_security_group_rule" "eks_node_eks_control_plane" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" # all traffic
  // which means eks_node accepting connection from eks_control_plane
  security_group_id = local.eks_node_sg_id
  source_security_group_id = local.eks_control_plane_sg_id
}

resource "aws_security_group_rule" "eks_node_vpc_cidr" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1" # all traffic
  // which means eks_node accepting connection from with the VPC CIDR as some PODS might be created in other Worker Nodes.
  // Hence we are providing access to the whole VPC CIDR, which means with our VPC if any PODS are created in any Worker Nodes,
  // then also they can communicate with the EKS Control Plane and other Worker Nodes.
  security_group_id = local.eks_node_sg_id
  cidr_blocks = ["10.0.0.0/16"]
}

# Open VPN
resource "aws_security_group_rule" "openvpn_public_443" {
  type      = "ingress"
  from_port = 443
  to_port   = 443
  protocol  = "tcp"
  # Where traffic is coming from Internet / public
  security_group_id = local.openvpn_sg_id
  cidr_blocks       = ["0.0.0.0/0"]
}

# Open VPN - Admin UI
resource "aws_security_group_rule" "openvpn_public_943" {
  type      = "ingress"
  from_port = 943
  to_port   = 943
  protocol  = "tcp"
  # Where traffic is coming from Internet / public
  security_group_id = local.openvpn_sg_id
  cidr_blocks       = ["0.0.0.0/0"]
}