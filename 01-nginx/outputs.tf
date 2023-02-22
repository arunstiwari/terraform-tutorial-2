output "load_balancer_arn" {
  value = aws_lb.nginx_lb.dns_name
}

output "subnet_ids" {
  value =aws_subnet.nginx_subnet.*
}