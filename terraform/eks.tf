module "eks" {
  source  = "terraform-aws-modules/eks/aws"

  name               = var.cluster_name
  kubernetes_version = "1.31"
  enable_cluster_creator_admin_permissions = true

  # Endpoint configuration - Enable private access for in-cluster API calls
  endpoint_public_access  = true
  endpoint_private_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Enable IRSA
  enable_irsa = true

  # Addons configuration
  addons = {
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
  }

  # Single node group
  eks_managed_node_groups = {
    general = {
      # Node group name must match ^[0-9A-Za-z][A-Za-z0-9-_]*
      name            = "general"
      use_name_prefix = false

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      iam_role_additional_policies = {
        AmazonEKSWorkerNodePolicy        = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
        AmazonEKS_CNI_Policy             = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
        AmazonEC2ContainerRegistryReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      }

      min_size     = 1
      max_size     = 2
      desired_size = 1

      disk_size = 20

      tags = {
        Environment = "dev"
      }
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}
