# AWS DR Terraform - Phase 1 Network

This environment builds the first network skeleton for the AWS DR plan.

## Scope

- VPC `10.20.0.0/16`
- Public subnets in `ap-northeast-2a` and `ap-northeast-2c`
- Private app subnets in `ap-northeast-2a` and `ap-northeast-2c`
- Private data subnets in `ap-northeast-2a` and `ap-northeast-2c`
- Internet Gateway
- Public, app, and data route tables
- NAT Gateway 1 when `dr_active=false`
- NAT Gateway 2 when `dr_active=true`
- Base security groups for ALB, EKS nodes, RDS, DMS, and future VPC endpoints

VPN, VPC endpoints, RDS, DMS, Route 53, EKS, and ALB activation are follow-up phases.

## Usage

```bash
cd infra/aws/terraform/envs/dr
AWS_PROFILE=kosa-team-snow AWS_REGION=ap-northeast-2 terraform init
AWS_PROFILE=kosa-team-snow AWS_REGION=ap-northeast-2 terraform validate
AWS_PROFILE=kosa-team-snow AWS_REGION=ap-northeast-2 terraform plan -var="dr_active=false"
AWS_PROFILE=kosa-team-snow AWS_REGION=ap-northeast-2 terraform plan -var="dr_active=true"
```

Copy `terraform.tfvars.example` to `terraform.tfvars` only on your local machine if you want local defaults. Do not commit `terraform.tfvars` or Terraform state files.
