# Creates VPC resources.
module "vpc" {
  source = "./modules/vpc"

  name = "eks"
  vpc_cidr_block = "172.31.0.0/16"
  instance_tenancy = "default"

  private_subnet_cidrs = ["172.31.0.0/26", "172.31.0.64/26"]
  private_subnet_azs = ["us-west-2a","us-west-2b"]

  public_subnet_cidrs = ["172.31.1.0/26", "172.31.1.64/26"]
  public_subnet_azs = ["us-west-2a", "us-west-2b"]

}
