module "eks-iam" {
  source = "./modules/eks_iam"

  name = "primary"
}
