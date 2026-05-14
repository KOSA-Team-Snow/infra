output "vpc_id" {
  description = "ID of the DR VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = aws_subnet.public[*].id
}

output "app_subnet_ids" {
  description = "Private app subnet IDs."
  value       = aws_subnet.app[*].id
}

output "data_subnet_ids" {
  description = "Private data subnet IDs."
  value       = aws_subnet.data[*].id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID."
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs."
  value       = aws_nat_gateway.this[*].id
}

output "route_table_ids" {
  description = "Route table IDs grouped by tier."
  value = {
    public = aws_route_table.public.id
    app    = aws_route_table.app[*].id
    data   = aws_route_table.data[*].id
  }
}

output "security_group_ids" {
  description = "Security group IDs grouped by purpose."
  value = {
    alb      = aws_security_group.alb.id
    eks_node = aws_security_group.eks_node.id
    rds      = aws_security_group.rds.id
    dms      = aws_security_group.dms.id
    vpce     = aws_security_group.vpce.id
  }
}
