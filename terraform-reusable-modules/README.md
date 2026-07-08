# Terraform Reusable Modules

Reusable S3 and DynamoDB modules for a URL-shortener service's storage layer, called once per environment (dev, qa, prod) with different inputs instead of copy-pasted resource blocks.

This is **Project 2** of a 7-project Terraform learning path. It builds on Project 1's workflow (provider config, variables, outputs, state) and introduces the concept that makes Terraform scale on real teams: modules.

## Business Scenario

The platform team is standing up the storage layer for a URL-shortener service: an S3 bucket for uploaded assets and a DynamoDB table mapping short codes to long URLs, needed identically shaped across dev, qa, and prod. Instead of hand-copying a `main.tf` three times (and forgetting to update one when the shape changes), the S3 bucket and DynamoDB table logic live in two reusable modules, called once per environment with different inputs.

## Architecture

```
                    +---------------------------+
                    |      modules/storage        |
                    |   (S3 bucket module)        |
                    +---------------------------+
                              ^
                              |  called by, with different inputs
    +------------------------+------------------------+
    |                        |                         |
+---------+            +---------+              +----------+
|   dev    |            |   qa     |              |   prod    |
+---------+            +---------+              +----------+
    |                        |                         |
    +------------------------+------------------------+
                              |  called by, with different inputs
                              v
                    +---------------------------+
                    |     modules/database         |
                    |   (DynamoDB table module)    |
                    +---------------------------+
```

Each environment directory has its own Terraform state. Applying `dev` does not touch `qa` or `prod`.

## Project Structure

```
terraform-reusable-modules/
|-- environments/
|   |-- dev/    {main.tf, variables.tf, locals.tf, outputs.tf, providers.tf, versions.tf, terraform.tfvars}
|   |-- qa/     (same file set as dev)
|   `-- prod/   (same file set as dev)
|-- modules/
|   |-- storage/   {main.tf, variables.tf, outputs.tf}  # S3 bucket + versioning
|   `-- database/  {main.tf, variables.tf, outputs.tf}  # DynamoDB table
`-- README.md
```

## Prerequisites

- Terraform >= 1.5 (https://developer.hashicorp.com/terraform/downloads)
- Docker (https://docs.docker.com/get-docker/)
- LocalStack running locally (https://docs.localstack.cloud/getting-started/installation/)

## Getting Started

Each environment is independent - run Terraform commands from inside each environment's folder, not from the repo root.

```bash
# 1. Make sure LocalStack is running
localstack start -d

# 2. Copy the example vars file and adjust if needed
cd environments/dev
cp terraform.tfvars.example terraform.tfvars

# 3. Initialize, review, apply
terraform init
terraform plan
terraform apply

# 4. Repeat for qa and prod
cd ../qa && terraform init && terraform apply
cd ../prod && terraform init && terraform apply

# 5. Tear down when done
cd ../dev && terraform destroy
cd ../qa && terraform destroy
cd ../prod && terraform destroy
```

Verify in LocalStack:
```bash
aws --endpoint-url=http://localhost:4566 s3 ls
aws --endpoint-url=http://localhost:4566 dynamodb list-tables
```

## Variables (per environment)

| Name | Description | Type | Default |
|---|---|---|---|
| environment | Environment name - must be dev, qa, or prod | string | none |
| project_name | Project name used as a naming prefix | string | none |
| billing_mode | DynamoDB billing mode | string | PAY_PER_REQUEST |
| tags | Common tags applied to all resources | map(string) | {} |

## Outputs (per environment)

| Name | Description |
|---|---|
| bucket_name | Name of the assets S3 bucket |
| table_name | Name of the URL mapping DynamoDB table |

## Learning Objectives

- Write a reusable module: input variables in, resources created, outputs out
- Call the same module multiple times with different inputs (module composition)
- Separate shared logic (`modules/`) from environment-specific configuration (`environments/`)
- Use variable validation blocks to catch bad input before `apply`
- Use locals to compute derived values (like a consistent naming prefix) once
- Understand that each environment folder has an independent state file

## Status

Work in progress - second project in the Terraform learning roadmap.
