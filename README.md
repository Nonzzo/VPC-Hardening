# AWS VPC Hardening with Bastion Host & SSM Access (Terraform)

This project provisions a secure, production-ready AWS VPC using Terraform, demonstrating two secure access patterns for private EC2 instances:
- **Bastion Host** (classic SSH jump box)
- **AWS SSM Session Manager** (no inbound SSH required)

The project is modular, extensible, and now includes advanced monitoring, compliance, and alerting features.

---

## Architecture Overview

```
                        ┌──────────────────────────────┐
                        │         Internet             │
                        └─────────────┬────────────────┘
                                      │
                        ┌─────────────┴─────────────┐
                        │      Public Subnet        │
                        │ ┌──────────────────────┐  │
                        │ │   Bastion Host (1)   │  │
                        │ └──────────────────────┘  │
                        │ ┌──────────────────────┐  │
                        │ │    NAT Gateway       │  │
                        │ └──────────────────────┘  │
                        └─────────────┬─────────────┘
                                      │
                        ┌─────────────┴─────────────┐
                        │      Private Subnet       │
                        │ ┌──────────────────────┐  │
                        │ │ Private Instance(s)  │  │
                        │ └──────────────────────┘  │
                        └─────────────┬─────────────┘
                                      │
                        ┌─────────────┴─────────────┐
                        │      SSM Access           │
                        └───────────────────────────┘
                                      │
                        ┌─────────────┴─────────────┐
                        │   CloudWatch Monitoring   │
                        └─────────────┬─────────────┘
                                      │
                        ┌─────────────┴─────────────┐
                        │   AWS Config Compliance   │
                        └───────────────────────────┘
```

- **Bastion Host**: Only public entry point for SSH, restricted by security group.
- **NAT Gateway**: Allows private instances to access the internet for updates, but not be accessed from the internet.
- **Private Instances**: No public IP, only accessible via the bastion or SSM.
- **SSM Access**: Enables secure, auditable access to private instances without opening SSH.
- **CloudWatch**: Monitors EC2 and sends notifications via SNS.
- **AWS Config**: Monitors compliance and configuration drift.

---

## File Structure

```
VPC-Hardening/
├── README.md
├── .gitignore
├── bastion-access
│   └── terraform
│       ├── main.tf
│       ├── outputs.tf│       
│       └── variables.tf
├── modules
│   ├── aws_config
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── bastion
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── cloudwatch
│   │   ├── cloudwatch-agent-config.json
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── cloudwatch_alarms
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── nat_gateway
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── private_instance
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── security
│   │   ├── nacls.tf
│   │   ├── outputs.tf
│   │   ├── security_groups.tf
│   │   └── variables.tf
│   ├── ssm_role
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── vpc
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── vpc_endpoints
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
└── ssm-access
    └── terraform
        ├── main.tf
        ├── outputs.tf        
        └── variables.tf
```

---

## Usage

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) v1.0.0 or later
- [AWS CLI](https://aws.amazon.com/cli/) configured
- An existing AWS EC2 key pair (for Bastion access)
- Your public IP address for SSH access (for Bastion access)
- For SSM: Attach the necessary IAM permissions to your user/role and install [Session Manager Plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)
- (Recommended) Add a `versions.tf` to pin provider versions for reproducibility

### Configuration

All variables are set in the respective `variables.tf` files. You can edit defaults or override with CLI/environment variables.

Example:
```hcl
variable "region" {
  default = "us-east-1"
}
variable "vpc_name" {
  default = "hardened-vpc"
}
# ...etc
```

### Deploy

Choose your access pattern:

#### Bastion Host
```sh
cd bastion-access/terraform
terraform init
terraform plan
terraform apply
```

#### SSM Access (No SSH Key Required)
```sh
cd ssm-access/terraform
terraform init
terraform plan
terraform apply
```

---

## Access Patterns

### 1. SSH via Bastion Host

1. **SSH to Bastion Host**
   ```sh
   ssh -i /path/to/Your-Key.pem ubuntu@<bastion-public-ip>
   ```

2. **Copy Private Key to Bastion**
   ```sh
   scp /path/to/Your-Key.pem ubuntu@<bastion-public-ip>:~/
   chmod 600 ~/Your-Key.pem
   ```

3. **SSH from Bastion to Private Instance**
   ```sh
   ssh -i ~/Your-Key.pem ubuntu@<private-instance-ip>
   ```
   > Default user for Ubuntu AMIs is `ubuntu`.

### 2. SSM Session Manager (No SSH Required)

1. Ensure your AWS CLI user/role has `AmazonSSMFullAccess` or the minimum required SSM permissions.
2. Start a session:
   ```sh
   aws ssm start-session --target <private-instance-id>
   ```
   Or use the AWS Console > Systems Manager > Session Manager.

---

## Monitoring & Compliance

- **CloudWatch**: EC2 instance metrics, logs, and alarms. Alerts sent to your configured email via SNS.
- **CloudWatch Alarms**: Predefined alarms for CPU, memory, and other metrics.
- **AWS Config**: Tracks configuration changes and enforces compliance rules (e.g., S3 encryption, no public EC2 IPs, root MFA enabled).

---

## Security Highlights

- **Bastion Host**: Only allows SSH from your IP (edit in `main.tf`).
- **Private Instance**: Only allows SSH from the bastion security group.
- **NAT Gateway**: Private instances have outbound internet, but no inbound from the internet.
- **Network ACLs**: Restrictive, only necessary ports open.
- **No hardcoded secrets**: Key names only, never private keys.
- **SSM Access**: No inbound SSH needed, all access is logged and auditable.
- **S3 Buckets**: Block public access, versioning, and encryption enabled.
- **IAM Roles**: Least privilege for EC2 and SSM.
- **AWS Config Rules**: Enforce best practices and compliance.

---

## Cleaning Up

To destroy all resources:
```sh
terraform destroy
```

---

## Navigation Guide

- **[bastion-access/terraform/](bastion-access/terraform/)**: Bastion-based access deployment.
- **[ssm-access/terraform/](ssm-access/terraform/)**: SSM-based access deployment (no SSH key required).
- **[modules/](modules/)**: Reusable infrastructure modules:
  - [`bastion/`](modules/bastion/): Bastion host resources
  - [`private_instance/`](modules/private_instance/): Private EC2 instances
  - [`nat_gateway/`](modules/nat_gateway/): NAT Gateway setup
  - [`security/`](modules/security/): Security groups and NACLs
  - [`ssm_role/`](modules/ssm_role/): SSM instance profile and permissions
  - [`vpc/`](modules/vpc/): VPC and subnet definitions
  - [`vpc_endpoints/`](modules/vpc_endpoints/): VPC endpoints for SSM and other services
  - [`cloudwatch/`](modules/cloudwatch/): CloudWatch log group, SNS, and monitoring
  - [`cloudwatch_alarms/`](modules/cloudwatch_alarms/): CloudWatch alarms for EC2
  - [`aws_config/`](modules/aws_config/): AWS Config rules, recorder, and compliance

---

## Extending

- Add more modules for additional AWS services as needed.
- Integrate with CI/CD for automated deployments.
- Use [Terraform Cloud](https://app.terraform.io/) or [Atlantis](https://www.runatlantis.io/) for team workflows.

---

## Best Practices

- **Pin provider versions** in a `versions.tf` for reproducibility.
- **Never commit secrets** (private keys, credentials, etc).
- **Review AWS Config and CloudWatch alarms** to ensure they meet your compliance needs.
- **Use separate state files** for prod/staging/dev environments.

---

**Questions?**  
Open an issue or check the module documentation for more details.