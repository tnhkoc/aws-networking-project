# AWS Networking Foundation (Terraform)

Multi-tier AWS VPC architecture with public/private subnets, IGW, NAT, Security Groups, NACLs, ALB, Bastion host, and tiered compute placeholders.

## Workflow
- main is protected (PR required)
- feature branches: feat/*, fix/*, docs/*, chore/*
- PR checks: terraform fmt + validate (CI)

## Local checks
```bash
cd terraform
terraform fmt -recursive
terraform init -backend=false
terraform validate