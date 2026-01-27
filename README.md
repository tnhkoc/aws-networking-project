# AWS Networking Project (Terraform) — VPC + ALB + Private EC2 + SSM + Remote State

> A production-minded AWS networking demo built with **Terraform modules**: public/private subnets, internet-facing ALB, private EC2 reachable via SSM (no SSH), and **remote state with locking**.

---

## What’s inside

- **Multi-AZ VPC** with public & private subnets
- **Internet-facing ALB** in public subnets
- **Private EC2** target behind ALB (no public IP)
- **SSM access** to the private instance (no SSH exposed)
- **NAT Gateway egress** for private subnet outbound
- **Network controls**: Security Groups + stateless **NACL** rules
- **Remote Terraform state**: **S3 backend + DynamoDB lock**
- CI workflow for Terraform (lint/validate/plan) under `.github/workflows`

---

## Architecture

### Network topology (high-level)

```mermaid
flowchart LR
  Internet((Internet)) -->|HTTP 80| ALB[ALB (Public)]
  subgraph VPC["VPC (Multi-AZ)"]
    direction LR

    subgraph Pub["Public Subnets (2x)"]
      ALB
      NAT[NAT Gateway]
      Bastion[Bastion (optional)]
    end

    subgraph Priv["Private Subnets (2x)"]
      App[EC2 App (Nginx)
Private IP only]
    end

    ALB -->|TargetGroup:80| App
    App -->|Outbound 80/443| NAT
    NAT --> Internet
    App -->|SSM| SSMEndpoint[(AWS Systems Manager)]
  end
```

> Note: this repo uses SSM without VPC endpoints; the private instance reaches SSM over the internet via NAT (outbound-only).

---

## Security model (what is allowed and why)

### Security Groups (stateful)

- **ALB SG**
  - Inbound: `80/tcp` from `0.0.0.0/0`
  - Outbound: to App SG on `app_port` (80)
- **App SG**
  - Inbound: `app_port` (80) **only from ALB SG**
  - Outbound: allowed (needed for SSM agent + package repos over NAT)
- **Bastion SG** (optional)
  - Keep it for learning / future SSH experiments; in the “SSM-only” model you can disable SSH ingress entirely.

### NACLs (stateless) — the part that usually bites

Because NACLs are **stateless**, you must explicitly allow **return traffic**.  
A common failure mode is “outbound works” but replies get dropped, causing:
- `dnf`/package repo timeouts
- SSM Agent “unable to acquire credentials / send request failed”
- intermittent health check failures in app bootstrapping

This repo uses the following intent:

**Public subnet NACL**
- Inbound: `80,443` from internet + ephemeral `1024-65535` (return traffic)
- Outbound: `80,443` + ephemeral

**Private subnet NACL**
- Inbound:
  - `app_port` from **VPC CIDR** (ALB → App)
  - ephemeral `1024-65535` from `0.0.0.0/0` (**NAT return traffic**)
- Outbound:
  - `80/443` to `0.0.0.0/0` (internet via NAT)
  - ephemeral `1024-65535` to `0.0.0.0/0`
  - DNS to VPC resolver (`VPC CIDR + .2`)

### Security flows diagram (ports)

```mermaid
flowchart LR
  Internet((Internet)) -->|80/tcp| ALB[ALB SG]
  ALB -->|80/tcp| App[App SG]
  App -->|443/tcp, 80/tcp| NAT[NAT GW]
  NAT --> Internet
  App -->|443/tcp| SSM[AWS SSM APIs]
  App -->|53/udp,tcp| DNS[VPC Resolver (.2)]
```

---

## Remote state + locking

Backend configuration is intentionally **not committed with real values**.

- `backend.hcl` is ignored (contains real bucket/key/account)
- Commit an example file instead (e.g. `backend.hcl.example`) and document expected fields

Example (redacted):

```hcl
bucket         = "***REDACTED***"
key            = "aws-networking-project/dev/terraform.tfstate"
region         = "eu-central-1"
dynamodb_table = "***REDACTED***"
encrypt        = true
```

Terraform backend stanza:

```hcl
terraform {
  backend "s3" {}
}
```

Locking uses DynamoDB table (key `LockID`) and prevents two concurrent applies.

---

## Repo structure

Target structure:

```text
.
├── README.md
├── terraform/
│   ├── modules/
│   ├── .gitignore
│   ├── .terraform.lock.hcl
│   ├── .tflint.hcl
│   ├── alb_attachments.tf
│   ├── backend.hcl.example
│   ├── backend.tf
│   ├── db.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── ssm.tf
│   ├── variables.tf
│   └── versions.tf
├── docs/
│   └── screenshots/
│       ├── s3-terraform-state.jpeg
│       └── target-group-healthy.jpeg
└── .github/
    └── workflows/
        ├── terraform-ci.yaml
        └── infracost.yaml
```

---

## How to run (demo)

### Prerequisites

- Terraform `>= 1.5` (this state was created with `1.14.3`)
- AWS credentials with permission to create VPC/EC2/ALB/IAM/S3/DynamoDB/SSM resources

### Initialize

From repo root:

```bash
cd terraform
terraform init -backend-config=backend.hcl
```

### Plan & apply

```bash
terraform plan
terraform apply
```

### Verify

1) ALB DNS output:

```text
aws-networking-project-dev-alb-840211004.eu-central-1.elb.amazonaws.com
```

2) HTTP response (ALB → Target → Nginx):

```bash
curl -i http://aws-networking-project-dev-alb-840211004.eu-central-1.elb.amazonaws.com | head -n 20
```

Sample output captured during the demo:

```text
HTTP/1.1 200 OK
Date: Thu, 22 Jan 2026 22:24:55 GMT
Content-Type: text/html
Content-Length: 38
Connection: keep-alive
Server: nginx/1.28.0
Last-Modified: Thu, 22 Jan 2026 22:21:06 GMT
ETag: "6972a2d2-26"
Accept-Ranges: bytes

hello from aws-networking-project-dev
```

3) Target Group health:

```bash
aws elbv2 describe-target-health --region eu-central-1 --target-group-arn <your_tg_arn>
```

![Target Group Healthy](docs/screenshots/target-group-healthy.jpeg)

Captured output:

```json
{
    "TargetHealthDescriptions": [
        {
            "Target": {
                "Id": "i-0c04a1dc455fb8cbc",
                "Port": 80
            },
            "HealthCheckPort": "80",
            "TargetHealth": {
                "State": "healthy"
            },
            "AdministrativeOverride": {
                "State": "no_override",
                "Reason": "AdministrativeOverride.NoOverride",
                "Description": "No override is currently active on target"
            }
        }
    ]
}
```

4) SSM agent online (private instance reachable without SSH):

```bash
aws ssm describe-instance-information --region eu-central-1 --filters Key=InstanceIds,Values=<instance_id>
```

Captured output:

```json
{
  "InstanceInformationList": [
    {
      "InstanceId": "i-01490b5633496647a",
      "PingStatus": "Online",
      "LastPingDateTime": "2026-01-23T01:20:58.158000+03:00",
      "AgentVersion": "3.3.3572.0",
      "IsLatestVersion": false,
      "PlatformType": "Linux",
      "PlatformName": "Amazon Linux",
      "PlatformVersion": "2023",
      "ResourceType": "EC2Instance",
      "IPAddress": "10.0.101.75",
      "ComputerName": "ip-10-0-101-75.eu-central-1.compute.internal",
      "SourceId": "i-01490b5633496647a",
      "SourceType": "AWS::EC2::Instance"
    }
  ]
}
```

5) Confirm remote state exists:

```bash
terraform state pull | head
```

![S3 Remote State](docs/screenshots/s3-terraform-state.jpeg)

Sample:

```json
# data.aws_availability_zones.available:
data "aws_availability_zones" "available" {
    group_names = [
        "eu-central-1-zg-1",
    ]
    id          = "eu-central-1"
    names       = [
        "eu-central-1a",
        "eu-central-1b",
        "eu-central-1c",
    ]
    region      = "eu-central-1"
    state       = "available"
    zone_ids    = [
        "euc1-az2",
        "euc1-az3",
        "euc1-az1",
    ]
}

# data.aws_iam_policy_document.ec2_assume_role:
data "aws_iam_policy_document" "ec2_assume_role" {
    id            = "2851119427"
    json          = jsonencode(
        {
            Statement = [
                {
                    Action    = "sts:AssumeRole"
                    Effect    = "Allow"
                    Principal = {
                        Service = "ec2.amazonaws.com"
                    }
                },
            ]
            Version   = "2012-10-17"
        }
    )
    minified_json = jsonencode(
        {
            Statement = [
```

### Destroy (recommended when you’re done)

```bash
terraform destroy
```

---

## Debug story (real issues + fixes)

### 1) ALB health checks failing / 502
**Symptom:** Unhealthy target, 502s or failing health checks.  
**Fix:** Ensure the **Target Group port matches the actual app port** (e.g. `app_port = 80`). Also avoid AWS TG name length constraints by generating deterministic short names.

### 2) Private instance couldn’t reach SSM / package repos
**Symptom:** SSM shows instance but session hangs; console logs show `SSM Agent unable to acquire credentials` and `send request failed`. Package installs time out.  
**Root cause:** NACL is stateless. Outbound traffic via NAT returns with **source = public internet IPs**, not VPC CIDR. If inbound ephemeral is restricted to `10.0.0.0/16`, replies get dropped.
**Fix:** Allow **inbound ephemeral (1024–65535) from 0.0.0.0/0** on the **private NACL** to permit NAT return traffic.

### 3) DNS failures in private subnet
**Symptom:** Intermittent repo/SSM failures even with 80/443 open.  
**Fix:** Add explicit DNS egress to VPC resolver (`cidrhost(vpc_cidr, 2)` on `53/udp` and `53/tcp`) in private NACL.

### 4) “Where is the lock file?”
**Note:** With DynamoDB locking, Terraform creates lock entries in the **DynamoDB table**, not a visible “lock file” in S3. You will see lock conflicts when running concurrent operations, but not a persistent file object in the bucket.

---

## Security scan

Terraform security scanning was executed with **tfsec** (Aqua). Summary:

```text
  counts
  ──────────────────────────────────────────
  modules downloaded   0
  modules processed    6
  blocks processed     134
  files read           24

  results
  ──────────────────────────────────────────
  passed               28
  ignored              7
  critical             0
  high                 0
  medium               0
  low                  0
```

> Note: tfsec is joining the Trivy family (see project announcement). This repo keeps the output for traceability, but you can swap to Trivy later without changing the infra design.

---

## Cost notes (don’t leave it running)

Main cost drivers:
- **NAT Gateway** (hourly + processed data) — usually the biggest surprise
- **ALB** (hourly + LCU usage)
- **EC2** instance hours + EBS storage
- S3/DynamoDB are typically minimal for this scale

For a demo, run → validate → **destroy** is the intended lifecycle.

