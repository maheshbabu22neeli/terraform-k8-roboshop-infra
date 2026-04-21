module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = "${var.project}-${var.environment}-eks-cluster"
  kubernetes_version = "1.34"

  addons = {
    coredns = {}
    eks-pod-identity-agent = {
      before_compute = true
    }
    kube-proxy = {}
    vpc-cni = {
      before_compute = true
    }
    metrics-server = {}
  }

  # Optional
  endpoint_public_access = false

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = true

  vpc_id                   = local.vpc_id
  subnet_ids               = local.private_subnet_ids
  control_plane_subnet_ids = local.private_subnet_ids

  # Control Plan SG ID
  create_security_group = false # this is for Control Plane SG, we will creat it, hence set it to false here
  security_group_id     = local.eks_control_plane_sg_id

  # Node Group SG ID
  create_node_security_group = false # this is for Node Group SG, we will creat it, hence set it to false here
  node_security_group_id     = local.eks_control_plane_sg_id


  # EKS Managed Node Group(s)
  eks_managed_node_groups = {
    spot_nodes = {
      capacity_type  = "SPOT"
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["c3.large", "c4.large", "c5.large", "c5d.large", "c5n.large", "c5a.large", "m7i-flex.large", "c7i-flex.large"]

      # Auto Scale for NodeGroup
      min_size     = 2
      max_size     = 10
      desired_size = 2

      iam_role_additional_policies = {
        amazon_ebs_csi_driver_policy = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy",
        amazon_efs_csi_driver_policy = "arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy"
      }
    }
  }

  tags = merge(
    {
      Name = "${var.project}-${var.environment}-eks-cluster"
    },
    local.common_tags
  )
}