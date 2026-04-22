# CloudCraft

A production-grade AWS platform engineering project built with Terraform, demonstrating how I would design and implement cloud infrastructure foundations from scratch — with security, observability, and operational excellence baked in from day one.

Built as a portfolio project to reflect the standards I apply in my day-to-day platform engineering work.

---

## Overview

CloudCraft is a fully automated, security-first AWS platform that provisions and manages:

- **Remote Terraform state** — S3 + DynamoDB with KMS encryption and state locking
- **Networking** — VPC with public/private subnets, NACLs, flow logs, and a locked-down default security group
- **Container registry** — ECR with image scanning, immutable tags, and lifecycle policies
- **CI/CD pipeline** — GitHub Actions with six stages including security scanning, manual approval gate, and image vulnerability scanning

All infrastructure is managed as code. No manual AWS console changes. No hardcoded values.

---

## Security Design

Security is not an afterthought in this project — it is a first-class design concern applied consistently across every layer.

### KMS Customer-Managed Keys
All sensitive resources use KMS CMKs rather than AWS-managed keys. This means:
- Full control over key policies and access
- Complete audit trail in CloudTrail for every key usage
- Ability to revoke access instantly by disabling the key

KMS CMKs are used for: Terraform state bucket, DynamoDB lock table, CloudWatch log groups, ECR repository.

### IAM and Least Privilege
- GitHub Actions authenticates via **OIDC** — no long-lived AWS access keys stored as secrets
- The `cloudcraft-role` IAM role is scoped to only the permissions required
- The default VPC security group is explicitly overridden to deny all traffic — any resource accidentally assigned to it is protected

### Network Security
- Public subnet has `map_public_ip_on_launch = false` — no accidental public IPs
- NACLs on both public and private subnets restrict traffic to what is explicitly needed
- VPC flow logs capture all traffic metadata to CloudWatch Logs (365-day retention) for audit and incident investigation
- Default security group locked down — no implicit allow-all

### Supply Chain Security
- **Gitleaks** scans git history for accidentally committed secrets on every pipeline run
- **Trivy** scans Terraform IaC for misconfigurations (HIGH/CRITICAL, hard fail)
- **Checkov** scans Terraform for security policy violations (hard fail)
- **Trivy** scans the built Docker image for vulnerabilities before it is pushed to ECR
- ECR has `scan_on_push = true` and immutable image tags — no tag overwriting

### Checkov Skip Justifications
Where Checkov checks are skipped, each skip is documented with a written justification in `.checkov.yaml`. No check is skipped without a reason.

---

## CI/CD Pipeline

The pipeline has six stages that run in sequence. A failure at any stage blocks progression.

```
code-quality → security-scan → docker → deploy-staging → approval → deploy-prod
```

| Stage | What it does |
|---|---|
| `code-quality` | `terraform fmt`, `terraform validate`, `terraform plan` |
| `security-scan` | Gitleaks (secrets), Trivy IaC scan, Checkov scan |
| `docker` | Build image, Trivy image scan, push to ECR |
| `deploy-staging` | `terraform apply`, `terraform test` |
| `approval` | Manual approval gate via GitHub Environments |
| `deploy-prod` | `terraform apply` to prod environment |

**Key design decisions:**
- Security scans run *before* any infrastructure changes — shift left
- Docker image is scanned for vulnerabilities *before* it is pushed to ECR
- Manual approval gate between staging and production — no automated prod deploys
- Terraform plan artifact is uploaded and reused in apply — the apply runs exactly what was planned

---

## Terraform Structure

```
terraform/
├── bootstrap/          # One-time setup: S3 state bucket, DynamoDB lock, KMS key
└── envs/
    └── dev/            # Dev environment
        ├── main.tf         # Provider, backend, data sources
        ├── variables.tf    # Input variables with defaults
        ├── locals.tf       # Local values (name_prefix)
        ├── vpc.tf          # VPC, subnets, NACLs, flow logs
        ├── ecr.tf          # ECR repository and lifecycle policy
        └── tests/
            └── vpc.tftest.hcl  # Terraform native tests
```

### Backend Configuration
Remote state is stored in S3 with:
- Server-side encryption using KMS CMK
- Versioning enabled — full history of state changes
- State locking via DynamoDB — prevents concurrent applies
- Access logging to a separate S3 bucket
- Lifecycle policy to expire old state versions after 90 days

### Terraform Tests
Native `terraform test` is used to validate infrastructure behaviour at plan time:
- VPC CIDR is correct
- DNS hostnames are enabled
- Subnet CIDRs are correct
- `map_public_ip_on_launch` is explicitly set to false

---

## Application

A minimal FastAPI application lives in `app/` — its purpose is to provide a real Docker build target for the pipeline.

```
app/
├── Dockerfile
├── main.py
└── requirements.txt
```

**Endpoints:**
- `GET /` — returns app name and version
- `GET /health` — returns health status

The app is intentionally minimal. The focus of this project is platform infrastructure, not application logic.

---

## Prerequisites

- AWS account
- Terraform `~> 1.14`
- GitHub repository with the following configured:
  - `AWS_ROLE_ARN` variable (for OIDC authentication)
  - `production` environment with a required reviewer (for manual approval gate)

---

## Getting Started

### 1. Bootstrap remote state

```bash
cd terraform/bootstrap
terraform init
terraform apply
```

This creates the S3 bucket, DynamoDB table, and KMS key used for remote state.

### 2. Deploy dev environment

```bash
cd terraform/envs/dev
terraform init
terraform apply
```

Or push to `master` to trigger the full CI/CD pipeline.

---

## Design Principles

- **Security first** — encryption, least privilege, and auditability are non-negotiable
- **No manual changes** — all infrastructure is managed as code
- **Shift left** — security scanning happens before infrastructure changes, not after
- **Justify exceptions** — every Checkov skip has a written reason
- **Production patterns** — this is built the way I would build it at work, not as a toy project

---

## Author

Silvia Istrate — Platform & DevOps Engineer  
[GitHub](https://github.com/silviaistr52-collab) · [LinkedIn](https://www.linkedin.com/in/silvia-istrate)