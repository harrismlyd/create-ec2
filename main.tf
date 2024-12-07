variable "name" {
  description = "name of application"
  type        = string
  default     = "harris"
}

data "aws_vpc" "my_vpc" {
  filter {
    name   = "tag:Name"
    values = ["${var.name}-*"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.my_vpc.id]
  }
  filter {
    name   = "tag:Name"
    values = ["*-public-*"]
  }
}

resource "aws_instance" "public" {
  ami                         = "ami-04c913012f8977029"
  instance_type               = "t2.micro"
  subnet_id                   = data.aws_subnets.public.ids[0]
  associate_public_ip_address = true
  key_name                    = "harris-key-pair" #Change to your keyname, e.g. jazeel-key-pair
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "${var.name}-ec2" #Prefix your own name, e.g. jazeel-ec2
  }
}

resource "aws_security_group" "allow_ssh" {
  name_prefix = "${var.name}-terraform-security-group" #Security group name, e.g. jazeel-terraform-security-group
  description = "Allow SSH inbound"
  vpc_id      = data.aws_vpc.my_vpc.id #VPC ID (Same VPC as your EC2 subnet above), E.g. vpc-xxxxxxx
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

output "public_ip" {
  value = aws_instance.public.public_ip
}

output "public_dns" {
  value = aws_instance.public.public_dns
}

output "vpc_id" {
  value = data.aws_vpc.my_vpc.id
}
