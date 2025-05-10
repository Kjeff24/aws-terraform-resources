# EC2 Instance Terraform Module

This Terraform configuration provisions an EC2 instance with optional VPC creation, security groups, and key pair management.

## Features

✅ **Flexible VPC Management**: Create a new VPC or use an existing one  
✅ **Modular Design**: Separate modules for VPC, EC2, Security Groups, and Key Pairs  
✅ **Key Pair Options**: Generate new keys, import existing keys, or use existing AWS key pairs  
✅ **Security Group Management**: Configurable SSH and HTTP access rules  
✅ **Encrypted Storage**: Root volumes are encrypted by default  

---

## Usage Modes

### Mode 1: Create New VPC (Default)

The module will create a complete VPC with public/private subnets, Internet Gateway, NAT Gateway, and route tables.

```hcl
module "ec2_with_new_vpc" {
  source = "./ec2-instance"

  region       = "us-east-1"
  project_name = "my-project"

  # VPC will be created automatically
  create_vpc = true
  
  networking = {
    vpc_cidr             = "10.0.0.0/16"
    public_subnet_count  = 2
    private_subnet_count = 2
    subnet_prefix_length = 24
    enable_dns_hostnames = true
    enable_dns_support   = true
  }

  # EC2 instance configuration
  instance_config = {
    ami_id                  = "ami-0c55b159cbfafe1f0"  # Replace with your AMI
    instance_type           = "t3.micro"
    subnet_id               = ""  # Will use first public subnet automatically
    security_group_ids      = []  # Will use created security group
    key_name                = ""  # Will use keypair module
    associate_public_ip     = true
    iam_instance_profile    = ""
    root_volume_size_gb     = 20
    root_volume_type        = "gp3"
    disable_api_termination = false
  }

  # Key pair configuration
  key_pair_config = {
    enabled              = true
    key_pair_name        = "my-ec2-key"
    generate_key_pair    = true
    public_key           = ""
    public_key_path      = ""
    key_algorithm        = "ED25519"
    rsa_bits             = 4096
    ecdsa_curve          = "P256"
    save_private_key_path = "./keys/private-key.pem"
    save_public_key_path  = "./keys/public-key.pub"
  }

  # Security settings
  ssh_allowed_cidrs  = ["0.0.0.0/0"]  # ⚠️ Restrict in production
  http_allowed_cidrs = ["0.0.0.0/0"]

  tags = {
    Environment = "Development"
    ManagedBy   = "Terraform"
    Project     = "EC2-Instance"
  }
}
```

---

### Mode 2: Use Existing VPC

Use your existing VPC infrastructure by providing VPC ID, subnet IDs, and VPC CIDR.

```hcl
module "ec2_with_existing_vpc" {
  source = "./ec2-instance"

  region       = "us-east-1"
  project_name = "my-project"

  # Use existing VPC
  create_vpc = false
  
  existing_vpc_id             = "vpc-0123456789abcdef0"
  existing_vpc_cidr           = "10.0.0.0/16"
  existing_public_subnet_ids  = ["subnet-0abc123", "subnet-0def456"]
  existing_private_subnet_ids = ["subnet-0ghi789", "subnet-0jkl012"]

  # EC2 instance configuration
  instance_config = {
    ami_id                  = "ami-0c55b159cbfafe1f0"
    instance_type           = "t3.micro"
    subnet_id               = "subnet-0abc123"  # Specify exact subnet or leave empty
    security_group_ids      = []  # Will create a new security group in your VPC
    key_name                = ""
    associate_public_ip     = true
    iam_instance_profile    = ""
    root_volume_size_gb     = 20
    root_volume_type        = "gp3"
    disable_api_termination = false
  }

  # Key pair configuration
  key_pair_config = {
    enabled              = true
    key_pair_name        = "my-ec2-key"
    generate_key_pair    = false
    public_key           = ""
    public_key_path      = "~/.ssh/id_ed25519.pub"  # Use your existing public key
    key_algorithm        = "ED25519"
    rsa_bits             = 4096
    ecdsa_curve          = "P256"
    save_private_key_path = ""
    save_public_key_path  = ""
  }

  # Security settings
  ssh_allowed_cidrs  = ["10.0.0.0/16"]  # Restrict to VPC CIDR
  http_allowed_cidrs = ["0.0.0.0/0"]

  tags = {
    Environment = "Development"
    ManagedBy   = "Terraform"
    Project     = "EC2-Instance"
  }
}
```

---

## Variables

### VPC Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `create_vpc` | `bool` | `true` | Whether to create a new VPC. Set to `false` to use an existing VPC. |
| `networking` | `object` | See defaults | VPC configuration (only used when `create_vpc = true`) |
| `existing_vpc_id` | `string` | `""` | ID of existing VPC (required when `create_vpc = false`) |
| `existing_vpc_cidr` | `string` | `""` | CIDR block of existing VPC (required when `create_vpc = false`) |
| `existing_public_subnet_ids` | `list(string)` | `[]` | List of existing public subnet IDs (required when `create_vpc = false`) |
| `existing_private_subnet_ids` | `list(string)` | `[]` | List of existing private subnet IDs (optional) |

### EC2 Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `instance_config` | `object` | N/A (required) | EC2 instance configuration including AMI, instance type, subnet, etc. |
| `key_pair_config` | `object` | See defaults | Key pair configuration for SSH access |

### Security Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ssh_allowed_cidrs` | `list(string)` | `["10.0.0.0/16"]` | CIDR blocks allowed SSH access (port 22) |
| `http_allowed_cidrs` | `list(string)` | `["0.0.0.0/0"]` | CIDR blocks allowed HTTP access (port 80) |

---

## Outputs

| Output | Description |
|--------|-------------|
| `vpc_id` | ID of the VPC (created or existing) |
| `vpc_cidr` | CIDR block of the VPC |
| `public_subnet_ids` | IDs of public subnets |
| `private_subnet_ids` | IDs of private subnets |
| `vpc_created` | Whether a new VPC was created (`true`) or existing used (`false`) |
| `ec2_sg_id` | ID of the EC2 security group |
| `instance_id` | ID of the EC2 instance |
| `public_ip` | Public IP address of the EC2 instance |
| `private_ip` | Private IP address of the EC2 instance |
| `key_pair_name` | Name of the SSH key pair |
| `generated_private_key_pem` | Generated private key (sensitive, only if generated) |

---

## Key Pair Management

### Option 1: Generate New Key Pair

```hcl
key_pair_config = {
  enabled              = true
  key_pair_name        = "my-new-key"
  generate_key_pair    = true
  public_key           = ""
  public_key_path      = ""
  key_algorithm        = "ED25519"  # or "RSA" or "ECDSA"
  rsa_bits             = 4096
  ecdsa_curve          = "P256"
  save_private_key_path = "./keys/private-key.pem"
  save_public_key_path  = "./keys/public-key.pub"
}
```

### Option 2: Import Existing Public Key

```hcl
key_pair_config = {
  enabled              = true
  key_pair_name        = "my-imported-key"
  generate_key_pair    = false
  public_key           = ""
  public_key_path      = "~/.ssh/id_ed25519.pub"
  key_algorithm        = "ED25519"
  rsa_bits             = 4096
  ecdsa_curve          = "P256"
  save_private_key_path = ""
  save_public_key_path  = ""
}
```

### Option 3: Use Existing AWS Key Pair

```hcl
key_pair_config = {
  enabled           = false
  key_pair_name     = "existing-aws-key-name"
  generate_key_pair = false
  # ... other fields can be default
}

instance_config = {
  # ...
  key_name = "existing-aws-key-name"
  # ...
}
```

---

## Examples

### Minimal Configuration (Create VPC)

```hcl
module "ec2_minimal" {
  source = "./ec2-instance"

  project_name = "test-ec2"

  instance_config = {
    ami_id                  = "ami-0c55b159cbfafe1f0"
    instance_type           = "t3.micro"
    subnet_id               = ""
    security_group_ids      = []
    key_name                = ""
    associate_public_ip     = true
    iam_instance_profile    = ""
    root_volume_size_gb     = 20
    root_volume_type        = "gp3"
    disable_api_termination = false
  }
}
```

### Production Configuration (Existing VPC)

```hcl
module "ec2_production" {
  source = "./ec2-instance"

  region       = "us-east-1"
  project_name = "prod-app"

  # Use existing VPC
  create_vpc                  = false
  existing_vpc_id             = "vpc-prod123"
  existing_vpc_cidr           = "172.31.0.0/16"
  existing_public_subnet_ids  = ["subnet-pub1", "subnet-pub2"]
  existing_private_subnet_ids = ["subnet-priv1", "subnet-priv2"]

  instance_config = {
    ami_id                  = "ami-prod-hardened-123"
    instance_type           = "t3.large"
    subnet_id               = "subnet-pub1"
    security_group_ids      = []
    key_name                = ""
    associate_public_ip     = true
    iam_instance_profile    = "EC2-SSM-Role"
    root_volume_size_gb     = 100
    root_volume_type        = "gp3"
    disable_api_termination = true
  }

  key_pair_config = {
    enabled              = true
    key_pair_name        = "prod-ec2-key"
    generate_key_pair    = false
    public_key_path      = "./keys/prod-key.pub"
    key_algorithm        = "ED25519"
    save_private_key_path = ""
    save_public_key_path  = ""
  }

  ssh_allowed_cidrs  = ["10.50.0.0/24"]  # Bastion host subnet only
  http_allowed_cidrs = ["0.0.0.0/0"]

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
    Project     = "WebApp"
    CostCenter  = "Engineering"
  }
}
```

---

## Requirements

- Terraform >= 1.0
- AWS Provider >= 4.0
- Valid AWS credentials configured

---

## Deployment Steps

1. **Initialize Terraform**:
   ```bash
   cd ec2-instance
   terraform init
   ```

2. **Review the plan**:
   ```bash
   terraform plan
   ```

3. **Apply the configuration**:
   ```bash
   terraform apply
   ```

4. **SSH into your instance** (if key was generated):
   ```bash
   chmod 400 ./keys/private-key.pem
   ssh -i ./keys/private-key.pem ec2-user@<public_ip>
   ```

---

## Security Considerations

⚠️ **Important Security Notes**:

- **SSH Access**: By default, `ssh_allowed_cidrs` is set to the VPC CIDR. For production, restrict to specific IP ranges.
- **Key Management**: Store private keys securely. Never commit them to version control.
- **IAM Roles**: Use IAM instance profiles instead of embedding credentials.
- **Security Groups**: Follow the principle of least privilege.
- **Encryption**: Root volumes are encrypted by default.

---

## Module Structure

```
ec2-instance/
├── main.tf              # Main configuration with VPC selection logic
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── backend.tf           # Backend configuration
├── README.md            # This file
└── modules/
    ├── vpc/             # VPC module (creates VPC resources)
    ├── ec2/             # EC2 instance module
    ├── security_groups/ # Security group module
    └── keypair/         # Key pair management module
```

---

## Troubleshooting

### VPC Not Found Error

If you see errors about VPC not found when `create_vpc = false`:
- Verify the `existing_vpc_id` is correct
- Ensure the VPC exists in the specified region
- Check AWS credentials have permission to describe VPCs

### Subnet Validation Errors

If subnet validation fails:
- Ensure all `existing_public_subnet_ids` exist in the specified VPC
- Verify subnet IDs are in the correct format (`subnet-xxxxx`)
- Check that at least one public subnet is provided

### Key Pair Issues

If SSH connection fails:
- Verify the key pair was created successfully
- Check file permissions on private key: `chmod 400 <key-file>`
- Ensure security group allows SSH from your IP
- Verify the correct username for your AMI (e.g., `ec2-user`, `ubuntu`, `admin`)

---

## License

MIT License - Feel free to use and modify as needed.
