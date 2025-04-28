# AWS VPC Hardening with Bastion Host & SSM Access (Terraform)

This project provisions a secure AWS VPC using Terraform, demonstrating two secure access patterns for private EC2 instances:
- **Bastion Host** (classic SSH jump box)
- **AWS SSM Session Manager** (no inbound SSH required)

All infrastructure is modular, clear, and extensible.

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
```

- **Bastion Host**: Only public entry point for SSH, restricted by security group.
- **NAT Gateway**: Allows private instances to access the internet for updates, but not be accessed from the internet.
- **Private Instances**: No public IP, only accessible via the bastion or SSM.
- **SSM Access**: Enables secure, auditable access to private instances without opening SSH.

---

## File Structure
```
── README.md
├── bastion-access
│   └── terraform
│       ├── main.tf
│       ├── outputs.tf│       
│       └── variables.tf
├── modules
│   ├── bastion
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

## Usage

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) v1.0.0 or later
- [AWS CLI](https://aws.amazon.com/cli/) configured
- An existing AWS EC2 key pair (for Bastion access)
- Your public IP address for SSH access (for Bastion access)
- For SSM: Attach the necessary IAM permissions to your user/role and install [Session Manager Plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)

### Configuration

All variables are set in [`terraform/variables.tf`](terraform/variables.tf). You can edit defaults there or override with CLI/environment variables.

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

```sh
cd terraform
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

## Security Highlights

- **Bastion Host**: Only allows SSH from your IP (edit in `main.tf`).
- **Private Instance**: Only allows SSH from the bastion security group.
- **NAT Gateway**: Private instances have outbound internet, but no inbound from the internet.
- **Network ACLs**: Restrictive, only necessary ports open.
- **No hardcoded secrets**: Key names only, never private keys.
- **SSM Access**: No inbound SSH needed, all access is logged and auditable.

---

## Cleaning Up

To destroy all resources:
```sh
terraform destroy
```

---

## Navigation Guide

- **[terraform/](terraform/)**: Main entrypoint for deploying the full stack.
- **[modules/](modules/)**: Reusable infrastructure modules:
  - [`modules/bastion/`](modules/bastion/): Bastion host resources
  - [`modules/private_instance/`](modules/private_instance/): Private EC2 instances
  - [`modules/nat_gateway/`](modules/nat_gateway/): NAT Gateway setup
  - [`modules/security/`](modules/security/): Security groups and NACLs
  - [`modules/vpc/`](modules/vpc/): VPC and subnet definitions
  - [`modules/vpc_endpoints/`](modules/vpc_endpoints/): VPC endpoints for SSM and other services
- **[bastion-access/terraform/](bastion-access/terraform/)**: Example configuration for Bastion-based access
- **[ssm-access/terraform/](ssm-access/terraform/)**: Example configuration for SSM-based access

---

## Extending

- Add more modules for additional AWS services as needed.
- Integrate with CI/CD for automated deployments.
- Use [Terraform Cloud](https://app.terraform.io/) or [Atlantis](https://www.runatlantis.io/) for team workflows.

---

**Questions?**  
Open an issue or check the module documentation for more details.****