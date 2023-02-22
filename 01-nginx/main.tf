# 1. Create VPC
resource "aws_vpc" "nginx_vpc" {
  cidr_block = var.cidr_block
  instance_tenancy = var.instance_tenancy
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support = var.enable_dns_support
  tags = {
    Name = "${var.prefix}-vpc"
  }
}

# 2. Create Public Subnet
resource "aws_subnet" "nginx_subnet" {
  count = length(data.aws_availability_zones.availability.names)
  vpc_id = aws_vpc.nginx_vpc.id
  map_public_ip_on_launch = "true"
  availability_zone = element(data.aws_availability_zones.availability.names.*,count.index)
  cidr_block = element(var.subnet_cidr_block, count.index)
  tags = {
    Name = "${var.prefix}-pub-subnet-${count.index}"
  }
}

# 3. Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.nginx_vpc.id
  tags = {
    Name = "${var.prefix}-igw"
  }
}

# 4. Create Public Route Table
resource "aws_route_table" "public_route_table" {
  count = length(data.aws_availability_zones.availability.names)
  vpc_id = aws_vpc.nginx_vpc.id
  tags = {
    Name = "${var.prefix}-pub-rt-${count.index}"
  }
}

# 5. Create Routes in the Route Table
resource "aws_route" "pub_internet_route" {
  count = length(data.aws_availability_zones.availability.names)
  route_table_id = element(aws_route_table.public_route_table.*.id,count.index)
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

# 6. Associate route table with subnet
resource "aws_route_table_association" "pub_rt_table_subnet_association" {
  count = length(data.aws_availability_zones.availability.names)
  route_table_id = element(aws_route_table.public_route_table.*.id, count.index)
  subnet_id = element(aws_subnet.nginx_subnet.*.id,count.index)
}

# 6.5 Create key pair
resource "aws_key_pair" "nginx_key_pair" {
  public_key = file("/Users/arunstiwari/keys-dir/nginx-demo-key-pair.pub")
  key_name = "nginx-demo-key-pair"
}

# 7. Creating EC2 instance
resource "aws_instance" "nginx_instance" {
  count = length(data.aws_availability_zones.availability.names)
  ami = "ami-0f8ca728008ff5af4"
  instance_type = "t2.micro"
  subnet_id = element(aws_subnet.nginx_subnet.*.id,count.index)
  vpc_security_group_ids = [aws_security_group.nginx_security_group.id]
  key_name = aws_key_pair.nginx_key_pair.id

  # Nginx install
  provisioner "file" {
    source = "nginx.sh"
    destination = "/tmp/nginx.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/nginx.sh",
      "sudo /tmp/nginx.sh"
    ]
  }

   connection {
     user = "ubuntu"
     private_key = file("/Users/arunstiwari/keys-dir/nginx-demo-key-pair")
     host = self.public_ip
   }

  tags = {
    Name = "${var.prefix}-nginx-instance"
  }

}

# 8. Create EC2 Security Group
resource "aws_security_group" "nginx_security_group" {
  vpc_id = aws_vpc.nginx_vpc.id
  ingress {
    from_port = 80
    protocol  = "tcp"
    to_port   = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    protocol  = "tcp"
    to_port   = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 9. Create ALB
resource "aws_lb" "nginx_lb" {
  name = var.lb_name
  subnets = data.aws_subnet_ids.nginx_subnet_ids.ids
  security_groups = [aws_security_group.nginx_lb_sg.id]
}

# 10. Create ALB Security Group
resource "aws_security_group" "nginx_lb_sg" {
  vpc_id = aws_vpc.nginx_vpc.id
  name = "nginx-lb-sg"
  ingress {
    from_port = 80
    protocol  = "tcp"
    to_port   = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 11. Create Target Group
resource "aws_lb_target_group" "nginx_lb_tg" {
  name     = "nginx-lb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.nginx_vpc.id
#  health_check {
#
#  }
}

# 12. Create Load Balancer Listener
resource "aws_lb_listener" "nginx_lb_listener" {
  load_balancer_arn = aws_lb.nginx_lb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.nginx_lb_tg.arn
  }
}

# 13. Register Target group
resource "aws_lb_target_group_attachment" "nginx_lb_tgt_attachment" {
  count = length(data.aws_availability_zones.availability.names)
  target_group_arn = aws_lb_target_group.nginx_lb_tg.arn
  target_id        = element(aws_instance.nginx_instance.*.id, count.index)
  port = 80
}