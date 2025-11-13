module "ssm_bastion" {
  source            = "./modules/ssm-bastion"
  vpc_id            = module.vpc.vpc_id
  public_subnet_id  = module.vpc.public_subnets[0]
  instance_type     = "t3.micro"
  instance_name     = "BastionHost"
  role_name         = "ssm-instance-role"
  instance_profile_name = "ssm-instance-profile"
  sg_name          = "bastion-sg"
  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}