output "aws_ami_id" {
    value=data.aws_ami.myapp-ami.id
}


output "instance" {
    value = aws_instance.myapp-server
}