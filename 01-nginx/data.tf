data "aws_availability_zones" "availability" {
  exclude_names = ["ap-south-1c"]
}

#data "aws_ami" "ubuntu" {
#  owners = []
#}