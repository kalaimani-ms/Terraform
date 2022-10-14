resource "aws_security_group" "myapp-sg" {
    name="myapp-sg"
    vpc_id=var.vpc_id
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

resource "aws_key_pair" "ssh-key"{
    key_name="terra"
    public_key=file(var.key_pair_path_location)
}

resource "aws_instance" "myapp-server" {
    ami=data.aws_ami.myapp-ami.id
    instance_type=var.instance_type

    subnet_id="${var.subnet_id}"
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