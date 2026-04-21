resource "aws_instance" "bastion" {
  ami                    = local.ami_id
  instance_type          = "t3.micro"
  subnet_id              = local.public_subnet_id
  vpc_security_group_ids = [local.bastion_sg_id]
  iam_instance_profile   = aws_iam_instance_profile.bastion.name
  user_data              = file("bastion.sh")

  # Increase Disk Space
  # This is the main disk where the operating system is installed
  # root_block_device refers to the storage (EBS volume) attached to the root filesystem of an EC2 instance
  root_block_device {
    volume_size = 50
    volume_type = "gp3"
    # EBS volume tags
    tags = merge(
      local.common_tags,
      {
        Name = "${var.project}-${var.environment}-bastion"
      }
    )
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project}-${var.environment}-bastion"
    }
  )
}

resource "aws_iam_role" "bastion" {
  name = local.bastion_role_name

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = local.bastion_role_name
    }
  )
}

resource "aws_iam_role_policy_attachment" "bastion" {
  for_each = toset(var.bastion_policy_arns)

  role       = aws_iam_role.bastion.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "bastion" {
  name = "${var.project}-${var.environment}-bastion"
  role = aws_iam_role.bastion.name
}