# AWS VPC Hardening with Bastion Host (Terraform)

This project provisions a secure AWS VPC using Terraform, demonstrating a classic bastion host pattern for accessing private EC2 instances. All infrastructure is modular and designed for clarity and extensibility.

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
                        └───────────────────────────┘
```

- **Bastion Host**: Only public entry point for SSH, restricted by security group.
- **NAT Gateway**: Allows private instances to access the internet for updates, but not be accessed from the internet.
- **Private Instances**: No public IP, only accessible via the bastion.

---

## File Structure

```
VPC-Hardening/
├── README.md
├── .gitignore
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── modules/
│   ├── bastion/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── private_instance/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security/
│   │   ├── main.tf
│   │   ├── security_groups.tf
│   │   ├── nacls.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── nat_gateway/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
```

---

## Usage

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) v1.0.0 or later
- [AWS CLI](https://aws.amazon.com/cli/) configured
- An existing AWS EC2 key pair (e.g., `Nonso-Key.pem`) You should use your own key, from herein refered to as Your-Key.pem
- Your public IP address for SSH access (update in `main.tf` as needed)

### Configuration

All variables are set in `terraform/variables.tf`. You can edit defaults there or override with CLI/environment variables.

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

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

---

## SSH Access Workflow

1. **SSH to Bastion Host**

   The bastion host is deployed in the public subnet with your key pair. Example:
   ```bash
   ssh -i /path/to/Your-Key.pem ubuntu@<bastion-public-ip>
   ```

2. **Copy Private Key to Bastion**

   To SSH from the bastion to the private instance, you need the private key on the bastion host:
   ```bash
   scp -i /path/to/Your-Key.pem /path/to/Your-Key.pem ubuntu@<bastion-public-ip>:~/
   ```
   On the bastion, set permissions:
   ```bash
   chmod 600 ~/Your-Key.pem
   ```

3. **SSH from Bastion to Private Instance**

   ```bash
   ssh -i ~/Your-Key.pem ubuntu@<private-instance-ip>
   ```

   > **Note:** The default user for Ubuntu AMIs is `ubuntu`.

---

## Security Highlights

- **Bastion Host**: Only allows SSH from your IP (edit in `main.tf`).
- **Private Instance**: Only allows SSH from the bastion security group.
- **NAT Gateway**: Private instances have outbound internet, but no inbound from the internet.
- **Network ACLs**: Restrictive, only necessary ports open.
- **No hardcoded secrets**: Key names only, never private keys.

---

## Cleaning Up

To destroy all resources:
```bash
terraform destroy
```

