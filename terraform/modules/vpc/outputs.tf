output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this[0].id
}

output "public_subnets" {
  description = "List of public subnet ids created by this module"
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnets" {
  description = "List of private subnet ids created by this module"
  value       = [for s in aws_subnet.private : s.id]
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway ids"
  value       = try(aws_nat_gateway.this[*].id, [])
}
