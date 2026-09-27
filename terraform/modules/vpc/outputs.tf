output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "public_route_table_id" {
  description = "The public route table ID"
  value       = aws_route_table.public.id
}

output "nat_gateway_ids" {
  description = "The NAT gateway IDs"
  value       = aws_nat_gateway.this[*].id
}
