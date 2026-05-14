output "vpc_id" {
  description = "ID of the DR VPC."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs for ALB and NAT Gateway placement."
  value       = module.network.public_subnet_ids
}

output "app_subnet_ids" {
  description = "Private app subnet IDs for EKS worker nodes."
  value       = module.network.app_subnet_ids
}

output "data_subnet_ids" {
  description = "Private data subnet IDs for RDS, DMS, and future endpoints."
  value       = module.network.data_subnet_ids
}

output "nat_gateway_ids" {
  description = "NAT Gateway IDs. One when dr_active=false, two when dr_active=true."
  value       = module.network.nat_gateway_ids
}

output "route_table_ids" {
  description = "Route table IDs grouped by network tier."
  value       = module.network.route_table_ids
}

output "security_group_ids" {
  description = "Security group IDs created by the network module."
  value       = module.network.security_group_ids
}
