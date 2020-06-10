# Creating the cluster
/*
module "eks_cluster" {
  source = "./modules/eks"

  cluster_name = "primary"
  role_arn = "${module.cluster_role.role_arn}"

  security_group_id = "${module.cluster_sg.security_group_id}"
  subnet_ids = "${concat(module.vpc.private_subnet_ids, module.vpc.public_subnet_ids)}"
}
*/
