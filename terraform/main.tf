provider "aws" {
  region = var.region
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version= "5.0.0"
  name   = var.vpc_name
  cidr   = var.vpc_cidr
  azs    = var.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  enable_nat_gateway = true
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.36.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.27"

  # Instead of `subnets = ...`, use:
  cluster_subnet_ids = module.vpc.private_subnets

  # Provide the VPC ID too:
  vpc_id = module.vpc.vpc_id

  # Define EKS-managed node groups inline:
  eks_managed_node_groups = {
    default = {
      desired_capacity = 2
      min_capacity     = 2
      max_capacity     = 4
      instance_types   = ["t3.medium"]
    }
  }

  # If you want to disable the default aws-auth ConfigMap management, you can:
  manage_aws_auth_configmap = false

  # And if you ever need to disable node group management (rare):
  # manage_eks_managed_node_groups = false

  # No need to touch `create_iam_service_linked_role`—it’s removed in v20+
  
  depends_on = [ module.vpc ]
}


module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  engine  = "mysql"
  engine_version = "8.0"
  instance_class  = "db.t3.micro"
  allocated_storage = 20
  name     = "finance"
  username = var.db_user
  password = var.db_pass
  vpc_security_group_ids = [module.vpc.default_security_group_id]
  db_subnet_group_name   = module.vpc.database_subnet_group_name
}

output "eks_cluster_id" {
  value = module.eks.cluster_id
}
output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
output "eks_cluster_ca_cert" {
  value = module.eks.cluster_certificate_authority_data
}
