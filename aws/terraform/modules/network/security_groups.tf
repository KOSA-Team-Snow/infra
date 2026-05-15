resource "aws_security_group" "alb" {
  name        = "sg-alb-${local.name_base}"
  description = "Allow HTTP and HTTPS ingress to the DR ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP redirect to HTTPS"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-alb-${local.name_base}"
  }
}

resource "aws_security_group" "eks_node" {
  name        = "sg-eks-node-${local.name_base}"
  description = "Security group for EKS managed worker nodes"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-eks-node-${local.name_base}"
  }
}

resource "aws_security_group_rule" "eks_node_from_alb_pod_port" {
  type                     = "ingress"
  security_group_id        = aws_security_group.eks_node.id
  source_security_group_id = aws_security_group.alb.id
  from_port                = 8000
  to_port                  = 8000
  protocol                 = "tcp"
  description              = "ALB to FlaskApp pod port for target-type ip"
}

resource "aws_security_group_rule" "eks_node_from_alb_nodeport" {
  type                     = "ingress"
  security_group_id        = aws_security_group.eks_node.id
  source_security_group_id = aws_security_group.alb.id
  from_port                = 30000
  to_port                  = 32767
  protocol                 = "tcp"
  description              = "ALB to NodePort fallback for target-type instance"
}

resource "aws_security_group_rule" "eks_node_self" {
  type                     = "ingress"
  security_group_id        = aws_security_group.eks_node.id
  source_security_group_id = aws_security_group.eks_node.id
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  description              = "Node and pod communication within the EKS node group"
}

resource "aws_security_group" "rds" {
  name        = "sg-rds-${local.name_base}"
  description = "Allow database access from EKS nodes and DMS only"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-rds-${local.name_base}"
  }
}

resource "aws_security_group" "dms" {
  name        = "sg-dms-${local.name_base}"
  description = "Security group placeholder for the future DMS replication instance"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Allow all outbound for initial DMS connectivity validation"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-dms-${local.name_base}"
  }
}

resource "aws_security_group_rule" "rds_from_eks_node" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.eks_node.id
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  description              = "FlaskApp on EKS to RDS"
}

resource "aws_security_group_rule" "rds_from_dms" {
  type                     = "ingress"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.dms.id
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  description              = "DMS to RDS target"
}

resource "aws_security_group" "vpce" {
  name        = "sg-vpce-${local.name_base}"
  description = "Allow HTTPS from the VPC to future interface endpoints"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-vpce-${local.name_base}"
  }
}
