output "vpc_id" {
    value = aws_vpc.my_vpc.id
}

output "security_group_id" {
    value = aws_security_group.security_group.id
}

output "subnet_id_a" {
    value = aws_subnet.my_subnet_a.id
}

output "subnet_id_b" {
    value = aws_subnet.my_subnet_b.id
}