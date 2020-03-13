provider "aws" {
  region = "us-west-1"
}

resource "aws_vpc" "terratest_net" {
  cidr_block = "10.99.0.0/16"
  tags = {
    Name = "Terratest VPC"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id = aws_vpc.terratest_net.id
  cidr_block = "10.99.1.0/24"
  availability_zone = "us-west-1a"
  tags = {
    Name = "Terratest subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.terratest_net.id
  tags = {
    Name = "Terratest gateway"
  }
}

resource "aws_route_table" "default" {
  vpc_id = aws_vpc.terratest_net.id 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
      Name = "Terratest route table"
    }
}

resource "aws_route_table_association" "route_table_assoc" {
  subnet_id = aws_subnet.subnet1.id
  route_table_id = aws_route_table.default.id
}


resource "aws_security_group" "terratest_sg" {
  name = "Terratest SG"
  description = "Terrtest SG -- Allow ssh"
  vpc_id = aws_vpc.terratest_net.id

  # This prevents problems when renaming SGs
  lifecycle {
    create_before_destroy = true
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "pub_ip" {
  instance = aws_instance.terratest_server.id
  vpc = true
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_key_pair" "terratest_key" {
  key_name = "terratest_key"

  # You can specify your own public key here
  public_key = 
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]  # Canonical
}

resource "aws_instance" "terratest_server" {
  ami = data.aws_ami.ubuntu.id
  availability_zone = "us-west-1a"
  instance_type = "t2.nano"
  key_name = aws_key_pair.terratest_key.id
  vpc_security_group_ids = [aws_security_group.terratest_sg.id]
  subnet_id = aws_subnet.subnet1.id
}

output "public_ip" {
  value = aws_eip.pub_ip.public_ip
}

