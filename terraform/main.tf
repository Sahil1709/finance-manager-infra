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
  version = "21.0.1"
  cluster_name    = var.cluster_name
  cluster_version = "1.27"
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id
  eks_managed_node_groups = {
    default = {
      desired_capacity = 2
      max_capacity     = 4
      min_capacity     = 2
      instance_types   = ["t3.medium"]
    }
  }
  # turn off auto mode (IAM roles, etc)
  depends_on = [module.vpc]
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
