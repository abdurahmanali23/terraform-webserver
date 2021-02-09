provider "aws" {
  region     = "us-east-1"
  access_key = "AKIA2QCJZHZA4KH3QU4Q"
  secret_key = "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"
}

resource "aws_vpc" "myvpc" {
    cidr_block = "10.0.0.0/16"
  tags = {
    Name = "essential-vpc"
  }
}

resource "aws_internet_gateway" "mygw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "essential-igw"
  }
}

resource "aws_route_table" "myroute" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mygw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.mygw.id
  }

  tags = {
    Name = "essentialroute"
  }
}

resource "aws_subnet" "mysubnet" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "essentialsubnet"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.mysubnet.id
  route_table_id = aws_route_table.myroute.id
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.mysubnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.mygw]
}

resource "aws_instance" "web-server" {
  ami           = "ami-047a51fa27710816e"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "Accesskey"
  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install httpd -y
              sudo systemctl start httpd
              sudo bash -c 'echo your very first web server > /var/www/html/index.html'
              EOF 
  tags = {
    Name = "first-web-server"
  }
}