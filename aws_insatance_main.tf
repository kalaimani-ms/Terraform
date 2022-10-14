provider "aws" {
    region="us-east-1"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.16.0"

  name = "myapp-vpc"
  cidr = var.vpc_cidr_block

  azs             = var.avail_zone
  public_subnets  = var.subnet_cidr_block

  public_subnet_tags= {
    Name="${var.env_prefix}-public-subnet"
  }

  tags = {
    Name="${var.env_prefix}-vpc"
  }
}


module "myapp-server" {
    source= "./modules/web_server"
    vpc_id=module.vpc.vpc_id
    my_ip=var.my_ip
    env_prefix=var.env_prefix
    avail_zone=var.avail_zone
    key_pair_path_location=var.key_pair_path_location
    instance_type=var.instance_type
    subnet_id=module.vpc.public_subnets[0]
}