provider "aws" {
    region="us-east-1"
}

variable "vpc_cidr_block" {}
variable "subnet_cidr_block" {}
variable "env_prefix" {}
variable "avail_zone"{}
variable "my_ip" {}
variable "instance_type" {}
variable "key_pair_path_location" {}

resource "aws_vpc" "myapp_vpc" {
    cidr_block=var.vpc_cidr_block
    tags = {
        Name="${var.env_prefix}-vpc"
    }
}

resource "aws_subnet"  "myapp_subnet-1" {
    vpc_id=aws_vpc.myapp_vpc.id
    cidr_block=var.subnet_cidr_block
    availability_zone=var.avail_zone
    tags = {
        Name="${var.env_prefix}-subnet-1"
    }
}

resource "aws_internet_gateway" "myapp-igw" {
    vpc_id=aws_vpc.myapp_vpc.id

    tags = {
        Name="${var.env_prefix}-igw"
    }
}

/*
resource "aws_route_table" "myapp_route_table" {
    vpc_id=aws_vpc.myapp_vpc.id

    route{
        cidr_block="0.0.0.0/0"
        gateway_id=aws_internet_gateway.myapp-igw.id
    }

    tags ={
        Name="${var.env_prefix}-rtb"
    }
}*/

resource "aws_default_route_table" "main_rtb" {
    default_route_table_id=aws_vpc.myapp_vpc.default_route_table_id

    route{
        cidr_block="0.0.0.0/0"
        gateway_id=aws_internet_gateway.myapp-igw.id
    }

    tags ={
        Name="${var.env_prefix}-rtb"
    }
}

resource "aws_route_table_association" "myapp-rtba" {
    subnet_id=aws_subnet.myapp_subnet-1.id
    route_table_id=aws_default_route_table.main_rtb.id
}

resource "aws_security_group" "myapp-sg" {
    name="myapp-sg"
    vpc_id=aws_vpc.myapp_vpc.id

    ingress{
        from_port="22"
        to_port="22"
        cidr_blocks=[var.my_ip]
        protocol="tcp"
    }
    ingress{
        from_port="8080"
        to_port="8080"
        cidr_blocks=["0.0.0.0/0"]
        protocol="tcp"
    }
    egress{
        from_port="0"
        to_port="0"
        cidr_blocks=["0.0.0.0/0"]
        protocol="-1"
        prefix_list_ids=[]
    }
    tags = {
        Name="${var.env_prefix}-sg"
    }
}

data "aws_ami" "myapp-ami" {
    most_recent= true
    owners=["amazon"]
    filter {
        name="name"
        values=["amzn2-ami-hvm-*-gp2"]
    }
    filter {
        name= "virtualization-type"
        values=["hvm"]
    }

}

output "aws_ami_id" {
    value=data.aws_ami.myapp-ami.id
}

resource "aws_key_pair" "ssh-key"{
    key_name="terra"
    public_key=file(var.key_pair_path_location)
}

resource "aws_instance" "myapp-server" {
    ami=data.aws_ami.myapp-ami.id
    instance_type=var.instance_type

    subnet_id=aws_subnet.myapp_subnet-1.id
    vpc_security_group_ids=[aws_security_group.myapp-sg.id]
    availability_zone=var.avail_zone

    associate_public_ip_address= true
    key_name=aws_key_pair.ssh-key.key_name

    user_data = <<EOF
                    #!/bin/bash
                    sudo yum update -y && sudo yum install docker -y
                    sudo usermod -aG docker ec2-user
                    sudo systemctl start docker
                    docker run -p 8080:80 nginx
                EOF
    tags ={
        Name="${var.env_prefix}-server"
    }
}

output "public_ip" {
    value=aws_instance.myapp-server.public_ip
}