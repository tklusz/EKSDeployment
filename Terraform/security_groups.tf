module "eks-sgs" {
  source = "./modules/eks_security_groups"

  name = "primary"
  vpc_id = module.eks_vpc.vpc_id
  user_ip = var.user_ip
}
