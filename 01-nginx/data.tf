data "aws_availability_zones" "availability" {
  exclude_names = ["ap-south-1c"]
}

#data "aws_ami" "ubuntu" {
#  owners = []
#}

data "aws_subnet_ids" "nginx_subnet_ids" {
  vpc_id = aws_vpc.nginx_vpc.id
  tags = {
    Name = "nginx*"
  }
}