provider "aws" {
    region="us-east-1"
}


resource "aws_vpc" "myapp_vpc" {
    cidr_block=var.vpc_cidr_block
    tags = {
        Name="${var.env_prefix}-vpc"
    }
}

module "myapp-subnet" {
    source="./modules/subnet"
    vpc_id=aws_vpc.myapp_vpc.id
    subnet_cidr_block=var.subnet_cidr_block
    avail_zone=var.avail_zone
    env_prefix=var.env_prefix
}

module "myapp-server" {
    source= "./modules/web_server"
    vpc_id=aws_vpc.myapp_vpc.id
    my_ip=var.my_ip
    env_prefix=var.env_prefix
    avail_zone=var.avail_zone
    key_pair_path_location=var.key_pair_path_location
    instance_type=var.instance_type
    subnet_id=module.myapp-subnet.subnet.id
}

output "public_ip" {
    value = module.myapp-server.instance.public_ip
}