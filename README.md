# Terraform AWS Infrastructure

A comprehensive Terraform configuration for provisioning a complete AWS infrastructure including VPC, EC2, RDS, S3, and DynamoDB.

## 📋 Architecture Overview

This configuration provisions:

- **Networking**: VPC with CIDR 10.0.0.0/16, 2 public subnets, 2 private subnets across 2 availability zones
- **Gateways**: Internet Gateway for public internet access, 2 NAT Gateways for private subnet outbound connectivity
- **Routing**: Public and private route tables with appropriate routing rules
- **Security Groups**: 
  - EC2 SG: Allows SSH (22), HTTP (80), HTTPS (443)
  - RDS SG: Allows MySQL (3306) only from EC2
- **Compute**: t2.micro EC2 instance with Ubuntu 22.04 LTS
- **Database**: RDS MySQL 8.0 (db.t3.micro) in private subnets
- **Storage**: S3 bucket for Terraform state with versioning and encryption
- **State Management**: DynamoDB table for Terraform state locking

## 🏗️ Infrastructure Diagram

```
┌─────────────────────────────────────────────────────────┐
│                      AWS Account                         │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────────────────────────────────────────┐   │
│  │         VPC (10.0.0.0/16)                        │   │
│  │                                                   │   │
│  │  ┌─────────────────────────────────────────┐    │   │
│  │  │  Internet Gateway                        │    │   │
│  │  └────────────────┬────────────────────────┘    │   │
│  │                   │                              │   │
│  │  ┌────────────────┼────────────────────────┐    │   │
│  │  │  Public Route Table                    │    │   │
│  │  └────────────────┼────────────────────────┘    │   │
│  │                   │                              │   │
│  │  ┌────────────────┼────────────────────────┐    │   │
│  │  │ Public Subnets │                        │    │   │
│  │  │ AZ1      │ AZ2 │                        │    │   │
│  │  │ ┌────┐  ┌────┐ │                        │    │   │
│  │  │ │EC2 │  │NAT │ │                        │    │   │
│  │  │ └────┘  └────┘ │                        │    │   │
│  │  └────────────────┼────────────────────────┘    │   │
│  │                   │                              │   │
│  │  ┌────────────────┼────────────────────────┐    │   │
│  │  │ Private Subnets│                        │    │   │
│  │  │ AZ1      │ AZ2 │                        │    │   │
│  │  │ ┌──────┐ ┌──────┐                       │    │   │
│  │  │ │ RDS  │ │ RDS  │ (Multi-AZ capable)   │    │   │
│  │  │ └──────┘ └──────┘                       │    │   │
│  │  └──────────────────────────────────────────┘    │   │
│  │                                                   │   │
│  └──────────────────────────────────────────────────┘   │
│                                                           │
│  ┌──────────────────┐  ┌──────────────────────────┐     │
│  │  S3 Bucket       │  │  DynamoDB Table          │     │
│  │  State Storage   │  │  State Locking           │     │
│  └──────────────────┘  └──────────────────────────┘     │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

## 📦 Files Structure

```
terraform-aws-infrastructure/
├── main.tf                 # Main resource definitions
├── variables.tf            # Input variables with validation
├── outputs.tf              # Output values
├── providers.tf            # Terraform provider configuration
├── terraform.tfvars        # Default variable values
├── user_data.sh            # EC2 bootstrap script
├── .gitignore              # Git ignore rules
└── README.md               # This file
```

## 🚀 Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [AWS CLI](https://aws.amazon.com/cli/) configured with credentials
- AWS account with appropriate permissions

### Deployment Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/Aamir-Yousaf/terraform-aws-infrastructure.git
   cd terraform-aws-infrastructure
   ```

2. **Initialize Terraform**
   ```bash
   terraform init
   ```

3. **Review and customize variables**
   ```bash
   # Edit terraform.tfvars to customize your deployment
   vim terraform.tfvars
   ```

4. **Plan the deployment**
   ```bash
   terraform plan -out=tfplan
   ```

5. **Apply the configuration**
   ```bash
   terraform apply tfplan
   ```

6. **View outputs**
   ```bash
   terraform output
   ```

## 📝 Variable Configuration

Key variables you should customize in `terraform.tfvars`:

```hcl
aws_region           = "us-east-1"          # AWS region
environment          = "dev"                # dev, staging, or prod
instance_type        = "t2.micro"           # EC2 instance type
db_password          = "ChangeMe123!"       # ⚠️ IMPORTANT: Set a strong password
skip_final_snapshot  = false                # Set to true in dev for faster cleanup
```

### Available Environments
- `dev`: For development (minimal resources, faster deployment)
- `staging`: For staging (moderate resources)
- `prod`: For production (includes Multi-AZ for RDS)

## 🔒 Security Considerations

### ⚠️ Critical Security Notes

1. **Database Password**: The default password in terraform.tfvars is for development only
   - Change `db_password` to a strong password before production deployment
   - Never commit production passwords to Git
   - Use AWS Secrets Manager or Parameter Store for production

2. **SSH Access**: Currently open to 0.0.0.0/0
   - Restrict to your IP: `cidr_blocks = ["YOUR_IP/32"]`
   - Use AWS Systems Manager Session Manager instead of SSH in production

3. **RDS Database**:
   - Deployed in private subnets (good!)
   - Only accessible from EC2 security group
   - Enable automated backups (configured)
   - Consider enabling encryption at rest

4. **Terraform State**:
   - Stored in S3 with versioning and encryption
   - Locked via DynamoDB to prevent concurrent modifications
   - Access restricted by S3 bucket policy
   - Remove public access (already configured)

### Security Best Practices Implemented

✅ VPC with public/private subnets
✅ NAT Gateways for private subnet egress
✅ Restricted security groups
✅ RDS in private subnets
✅ State encryption and locking
✅ EBS encryption-ready
✅ IAM-ready for enhanced access control

## 🔗 Connection Guide

### Connect to EC2 Instance

```bash
# Get the public IP
EC2_IP=$(terraform output -raw ec2_public_ip)

# SSH into the instance
ssh -i /path/to/key.pem ubuntu@$EC2_IP
```

### Connect to RDS Database

From the EC2 instance:

```bash
# Get RDS endpoint
RDS_ENDPOINT=$(terraform output -raw rds_address)
DB_NAME=$(terraform output -raw rds_database_name)

# Connect to MySQL
mysql -h $RDS_ENDPOINT -u admin -p -D $DB_NAME
```

Or locally (requires VPN/Bastion):

```bash
# Port forward through EC2 (if needed)
ssh -i /path/to/key.pem -L 3306:RDS_ENDPOINT:3306 ubuntu@EC2_IP

# Then connect locally
mysql -h 127.0.0.1 -u admin -p -D appdb
```

## 📊 Monitoring and Maintenance

### View All Outputs

```bash
terraform output
```

### View Specific Output

```bash
terraform output vpc_id
tf-ec2_public_ip
terraform output rds_endpoint
```

### Backup

```bash
# Create a backup of Terraform state
aws s3 cp s3://YOUR_STATE_BUCKET/terraform/state ./terraform.state.backup
```

## 🧹 Cleanup

To destroy all resources:

```bash
# Destroy resources
tf-destroy

# Confirm when prompted
```

⚠️ **Warning**: This will delete:
- VPC and all subnets
- EC2 instances
- RDS database (unless you set skip_final_snapshot = true)
- NAT Gateways and Elastic IPs
- S3 bucket and DynamoDB table are retained for safety

## 📈 Scaling and Customization

### Increase EC2 Instance Capacity

Edit `terraform.tfvars`:
```hcl
instance_type = "t2.small"  # or t2.medium, t3.small, etc.
```

### Scale RDS Database

```hcl
db_instance_class    = "db.t3.small"
db_allocated_storage = 50
multi_az             = true  # For production HA
```

### Add More Subnets

Modify the count in `main.tf`:
```hcl
resource "aws_subnet" "public" {
  count = 3  # Creates 3 subnets instead of 2
  ...
}
```

## 🐛 Troubleshooting

### Issue: Terraform Apply Fails

```bash
# Validate configuration
tf-validate

# Format code
tf-fmt -recursive

# Check syntax
tf-console
```

### Issue: Can't Connect to EC2

```bash
# Check security group rules
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Check instance status
aws ec2 describe-instance-status --instance-ids i-xxxxx
```

### Issue: RDS Connection Refused

```bash
# Verify RDS is running
aws rds describe-db-instances --db-instance-identifier dev-mysql-db

# Check security group allows EC2
aws ec2 describe-security-group-rules --group-id sg-xxxxx
```

### Enable Debug Logging

```bash
export TF_LOG=DEBUG
tf-apply
```

## 📚 Useful Commands

```bash
# Format Terraform files
tf-fmt -recursive

# Validate configuration
tf-validate

# Plan with detailed output
tf-plan -detailed-exitcode -out=tfplan

# Apply with auto-approval (use cautiously!)
tf-apply -auto-approve

# Destroy specific resource
tf-destroy -target aws_instance.main

# Refresh state
tf-refresh

# Show resource details
tf-show aws_instance.main
```

## 🔄 State Management

### Enable Remote Backend (After Initial Apply)

1. Note the output values:
   ```bash
   tf-output terraform_backend_config
   ```

2. Uncomment backend configuration in `main.tf`:
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "dev-terraform-state-123456789"
       key            = "terraform/state"
       region         = "us-east-1"
       encrypt        = true
       dynamodb_table = "dev-terraform-locks"
     }
   }
   ```

3. Re-initialize:
   ```bash
   tf-init
   ```

## 📞 Support and Documentation

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [Terraform Remote State](https://www.terraform.io/language/state/remote)

## 📄 License

This Terraform configuration is provided as-is for educational and commercial use.

## ⭐ Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

---

**Created by**: Aamir Yousaf
**Last Updated**: 2026-04-18
**Terraform Version**: >= 1.0
**AWS Provider Version**: ~> 5.0