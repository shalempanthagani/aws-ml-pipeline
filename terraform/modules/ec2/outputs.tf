output "alb_dns_name"          { value = aws_lb.main.dns_name }
output "alb_listener_arn"      { value = aws_lb_listener.http.arn }
output "alb_security_group_id" { value = aws_security_group.alb.id }
output "instance_id"           { value = aws_instance.spring_boot.id }