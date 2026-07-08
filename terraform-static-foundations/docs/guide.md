# Terraform Static Foundations - Implementation Guide

## Project Overview

This is Project 1 in a 7-project Terraform learning path. It teaches infrastructure-as-code fundamentals by solving a real business problem: replacing manual S3 bucket configuration with reproducible, version-controlled Terraform code.

## The Business Scenario

Your marketing team needs to upload static website assets (HTML, CSS, images) to S3. Currently they:

- Manually create buckets through the AWS Console
- Struggle to remember configurations
- Cannot easily reproduce environments
- Have no change history or review process

Solution: use Terraform to define the S3 bucket configuration as code.

## Learning Environment

We use LocalStack (a local AWS emulator) instead of real AWS so you can:

- Experiment safely without AWS costs
- Work offline
- Avoid credential and permission issues
- Reset anytime by restarting the LocalStack container

## Architecture

```
+-------------+      +--------------+      +------------+      +----------+
| Terraform   | ---> | AWS Provider | ---> | LocalStack | ---> | S3       |
| CLI (local) |      | (configured) |      | (Docker)   |      | Bucket   |
+-------------+      +--------------+      +------------+      +----------+
```

## Prerequisites

Before starting, ensure you have:

**Terraform >= 1.5**
```
terraform version
```

**Docker** (for LocalStack)
```
docker --version
```

**LocalStack CLI running locally**
```
localstack start -d
curl http://localhost:4566/_localstack/health
```

**(Optional) tflocal wrapper** - automates LocalStack endpoint configuration
```
pip install terraform-local
```

## Step-by-Step Implementation

### Step 1: Define Version Constraints (versions.tf)

What we're doing: specifying Terraform and provider version requirements.

Why: ensures consistent behavior - everyone on your team uses compatible versions.

Create `versions.tf`:

```hcl
terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

Key concepts:
- `required_version`: minimum Terraform CLI version
- `required_providers`: specifies provider source and version constraints
- `~> 5.0`: allows any 5.x version (flexible but safe)

### Step 2: Configure AWS Provider (providers.tf)

What we're doing: pointing the AWS provider at LocalStack instead of real AWS.

Why: work locally without AWS credentials or costs.

Create `providers.tf`:

```hcl
provider "aws" {
  region = "us-east-1"

  # LocalStack configuration
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # Required for S3 against a bare host:port endpoint (see note below)
  s3_use_path_style = true

  endpoints {
    s3 = "http://localhost:4566"
  }
}
```

Key concepts:
- `endpoints.s3`: redirects S3 API calls to LocalStack
- `access_key` / `secret_key`: dummy values (LocalStack does not validate them)
- `skip_*`: bypasses AWS API checks that would fail against LocalStack
- `s3_use_path_style`: **required with this endpoint.** LocalStack distinguishes path-style from virtual-hosted-style S3 requests by the `Host` header. An endpoint of `http://localhost:4566` is not prefixed with `s3.`, so the SDK's default virtual-hosted-style requests will not resolve correctly. Setting this to `true` forces path-style requests (`http://localhost:4566/bucket-name/key`), which works reliably against a bare endpoint. The alternative is to use the endpoint `http://s3.localhost.localstack.cloud:4566` instead, which supports virtual-hosted-style natively - either approach works, but pick one.

Alternative: use the `tflocal` wrapper instead, which configures all of this automatically.

### Step 3: Define Input Variables (variables.tf)

What we're doing: creating parameterized inputs for our infrastructure.

Why: makes the config reusable across environments (dev, staging, prod).

Create `variables.tf`:

```hcl
variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "bucket_name_prefix" {
  description = "Prefix for S3 bucket name (will be combined with environment)"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
```

Key concepts:
- `type`: enforces variable type (string, number, bool, list, map, object)
- `description`: documents purpose for team members
- `default`: optional fallback value (if not provided)

### Step 4: Create S3 Bucket Resource (main.tf)

What we're doing: defining the actual S3 bucket infrastructure.

Why: this is the core resource we're managing.

Create `main.tf`:

```hcl
resource "aws_s3_bucket" "static_site" {
  bucket = "${var.bucket_name_prefix}-${var.environment}"

  tags = merge(
    var.tags,
    {
      Name        = "${var.bucket_name_prefix}-${var.environment}"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

resource "aws_s3_bucket_versioning" "static_site" {
  bucket = aws_s3_bucket.static_site.id

  versioning_configuration {
    status = "Enabled"
  }
}
```

Key concepts:
- `resource "aws_s3_bucket"`: creates an S3 bucket
- `"${var.bucket_name_prefix}-${var.environment}"`: string interpolation for dynamic naming
- `merge()`: combines user-supplied tags with default tags
- `aws_s3_bucket.static_site.id`: references the bucket resource (creates a dependency)
- Versioning is a separate resource - this has been required since AWS provider v4.0; it is no longer a nested block on `aws_s3_bucket` itself

### Step 5: Define Outputs (outputs.tf)

What we're doing: exposing important values after creation.

Why:
- Reference bucket details in other Terraform configurations
- Display info to users after `terraform apply`
- Use in automation scripts

Create `outputs.tf`:

```hcl
output "bucket_name" {
  description = "Name of the created S3 bucket"
  value       = aws_s3_bucket.static_site.bucket
}

output "bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.static_site.arn
}
```

Key concepts:
- `value`: pulls an attribute from the resource (bucket name, ARN)
- Outputs are printed after `terraform apply`
- Can be referenced by other configurations via `terraform_remote_state`

Note: the original draft of this guide also included a `bucket_region` output referencing `aws_s3_bucket.static_site.region`. That attribute does exist on current AWS provider releases, but its availability depends on the exact provider version Terraform resolves under the `~> 5.0` constraint. It is left out here to keep this guide version-safe; if you want it, add it and let `terraform plan` confirm whether your resolved provider version supports it.

### Step 6: Set Variable Values (terraform.tfvars)

What we're doing: providing actual values for our variables.

Why: separates configuration from code (different values per environment).

Create `terraform.tfvars` (not committed to version control):

```hcl
environment        = "dev"
bucket_name_prefix = "mystatic"

tags = {
  Project    = "TerraformLearning"
  Owner      = "DevTeam"
  CostCenter = "Engineering"
}
```

Key concepts:
- Terraform auto-loads `terraform.tfvars`
- Never commit secrets here (use environment variables or a secrets manager)
- You can have multiple `.tfvars` files (e.g. `dev.tfvars`, `prod.tfvars`)

Create `terraform.tfvars.example` (template for team members, committed to version control):

```hcl
environment        = "dev"
bucket_name_prefix = "your-bucket-prefix"

tags = {
  Project    = "YourProject"
  Owner      = "YourName"
  CostCenter = "YourTeam"
}
```

## Running Your Infrastructure

### 1. Initialize Terraform

```
terraform init
```

What happens: downloads the AWS provider plugin, initializes the backend, creates the `.terraform/` directory.

Expected output: `Terraform has been successfully initialized!`

### 2. Validate Configuration

```
terraform validate
```

What happens: checks syntax and configuration validity.

Expected output: `Success! The configuration is valid.`

### 3. Format Code

```
terraform fmt
```

What happens: auto-formats `.tf` files to standard style.

### 4. Preview Changes

```
terraform plan
```

What happens: shows what will be created, modified, or destroyed. Does NOT make changes (dry run). Validates provider connectivity.

Expected output: `Plan: 2 to add, 0 to change, 0 to destroy.`

Read carefully: review all proposed changes before applying.

### 5. Apply Changes

```
terraform apply
```

What happens: shows the plan again, asks for confirmation, creates resources, updates the state file.

Steps: review the plan, type `yes` when prompted, wait for completion.

Expected output:

```
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.

Outputs:

bucket_arn = "arn:aws:s3:::mystatic-dev"
bucket_name = "mystatic-dev"
```

### 6. Verify Resources

Check the bucket exists in LocalStack:

```
aws --endpoint-url=http://localhost:4566 s3 ls
```

Expected output: `mystatic-dev`

Inspect the state file:

```
terraform show
```

Shows all resources and their attributes.

### 7. Make Changes

Try modifying a resource. Edit `terraform.tfvars`:

```hcl
tags = {
  Project    = "TerraformLearning"
  Owner      = "DevTeam"
  CostCenter = "Engineering"
  UpdatedBy  = "MyName"
}
```

Preview changes:
```
terraform plan
```
Shows: `Plan: 0 to add, 1 to change, 0 to destroy`

Apply changes:
```
terraform apply
```

Key concept: Terraform compares desired state (your code) against actual state (the real resources).

### 8. Destroy Infrastructure

```
terraform destroy
```

What happens: shows what will be deleted, asks for confirmation, removes all resources.

When to use: cleaning up test environments, tearing down temporary infrastructure, stopping costs.

Expected output: `Destroy complete! Resources: 2 destroyed.`

## Key Terraform Concepts

### State Management

`terraform.tfstate`:
- A JSON file tracking resource metadata
- Maps your Terraform config to real-world resources
- Critical file - never manually edit; commit carefully
- Contains sensitive data (encrypt it in production)

State commands:
```
terraform state list              # List all resources
terraform state show <resource>   # Show resource details
```

### Terraform Workflow

```
init -> validate -> plan -> apply -> destroy
```

- `init`: download providers, initialize backend
- `validate`: check syntax and configuration
- `plan`: preview changes (dry run)
- `apply`: create or update resources
- `destroy`: remove all resources

### Variables vs Locals vs Outputs

| Type      | Purpose         | Scope               |
|-----------|-----------------|----------------------|
| Variables | User inputs     | Entire config        |
| Locals    | Computed values | Entire config        |
| Outputs   | Expose values   | External consumers   |

Example:

```hcl
variable "env" {}                # Input from user

locals {
  bucket = "${var.env}-bucket"   # Computed value
}

output "name" {                  # Exposed to user
  value = local.bucket
}
```

### Resource Naming Best Practices

Bucket naming pattern: `<prefix>-<environment>-<purpose>`

Good: `mystatic-dev-website`, `acme-prod-assets`
Bad: `bucket123` (not descriptive), `MyBucket` (uppercase is not allowed in S3 bucket names)

## Troubleshooting

**Issue: "Error creating S3 bucket: BucketAlreadyExists"**
Cause: bucket name already in use (S3 names are globally unique).
Solution: change `bucket_name_prefix` in `terraform.tfvars`.

**Issue: "Error: connection refused localhost:4566"**
Cause: LocalStack is not running.
Solution:
```
localstack status
localstack start -d
```

**Issue: S3 requests fail or the bucket cannot be found after creation**
Cause: missing `s3_use_path_style = true` in the provider block (see Step 2).
Solution: add it, or switch the S3 endpoint to `http://s3.localhost.localstack.cloud:4566`.

**Issue: "No changes. Infrastructure is up-to-date."**
Cause: no differences between code and actual state.
Solution: this is normal - it means infrastructure matches your code.

**Issue: state file corruption**
Prevention: use remote state (S3 backend) in production, enable state locking, never manually edit `terraform.tfstate`.
Recovery:
```
terraform state pull > backup.tfstate   # Back up state
terraform import <resource> <id>        # Re-import if needed
```

## What We Learned

By completing this project, you now understand:

- Infrastructure as code: define infrastructure in version-controlled files
- Terraform workflow: init -> validate -> plan -> apply -> destroy
- Provider configuration: connect to cloud APIs (LocalStack, AWS)
- Resource definition: create S3 buckets with Terraform
- Variable parameterization: make configs reusable across environments
- State management: how Terraform tracks infrastructure
- Outputs: expose resource details for external use
- Safe testing: use LocalStack to experiment without cost

## Next Steps

### Enhance This Project

Add a bucket policy:
```hcl
resource "aws_s3_bucket_policy" "static_site" {
  # allow public read access
}
```

Enable static website hosting:
```hcl
resource "aws_s3_bucket_website_configuration" "static_site" {
  # configure index.html, error.html
}
```

Add lifecycle rules:
```hcl
resource "aws_s3_bucket_lifecycle_configuration" "static_site" {
  # delete old versions after 90 days
}
```

Multiple environments: create `dev.tfvars`, `staging.tfvars`, `prod.tfvars`, then run:
```
terraform apply -var-file=prod.tfvars
```

### Move to Real AWS

When ready to use real AWS:

1. Remove LocalStack configuration from `providers.tf`:
```hcl
provider "aws" {
  region = "us-east-1"
  # remove endpoints, skip_*, s3_use_path_style, and dummy credentials
}
```
2. Configure real AWS credentials: `aws configure`
3. Test with `terraform plan` first (no costs, no changes)

### Continue Learning Path

This is Project 1 of 7. The rest of the roadmap:

- Project 2: Reusable Modules - S3 + DynamoDB across dev/qa/prod
- Project 3: Serverless API - Lambda + API Gateway + IAM
- Project 4: Event-Driven Pipeline - EventBridge, SNS, SQS, Lambda
- Project 5: Web App Infrastructure - networking, compute, storage, IAM
- Project 6: Monorepo Refactor - consolidate everything into one production-grade repo
- Project 7: Production Simulation - tickets, incidents, and code reviews

## Additional Resources

- Terraform documentation: https://developer.hashicorp.com/terraform
- AWS provider documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- LocalStack documentation: https://docs.localstack.cloud

## Summary Cheat Sheet

```
terraform init                                    # Initialize
terraform validate                                # Validate
terraform fmt                                      # Format
terraform plan                                     # Preview
terraform apply                                    # Create/update
terraform show                                     # Show current state
terraform state list                               # List resources
terraform destroy                                  # Delete
aws --endpoint-url=http://localhost:4566 s3 ls     # Verify in LocalStack
```