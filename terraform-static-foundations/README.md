# Terraform Static Foundations

Infrastructure-as-code for a startup's static marketing site assets - replacing manual S3 console clicks with a reviewable, repeatable Terraform workflow, running locally against LocalStack.

This is **Project 1** of a 7-project Terraform learning path. It intentionally covers a small surface area (a single S3 bucket) so the focus stays on the Terraform *workflow* - provider config, variables, state - before anything more complex gets layered on top.

## Business Scenario

The marketing team's static site assets have historically been uploaded to S3 by hand. That works until someone forgets a step, misconfigures a setting, or leaves the company without documenting what they clicked. This project makes the bucket's configuration reproducible, reviewable, and version-controlled.

## Architecture

```
+----------------------+
|   Terraform CLI      |
|  (your machine)      |
+----------+-----------+
           | AWS provider, endpoint -> LocalStack
           v
+------------------------------+
|   LocalStack (Docker)         |
|  +----------------------+    |
|  |   S3 Bucket            |    |
|  |  - versioning          |    |
|  |  - tags                |    |
|  |  - bucket policy       |    |
|  +----------------------+    |
+------------------------------+
```

## Prerequisites

- Terraform >= 1.5 (https://developer.hashicorp.com/terraform/downloads)
- Docker (https://docs.docker.com/get-docker/)
- LocalStack running locally (https://docs.localstack.cloud/getting-started/installation/)
- (optional, but recommended) tflocal - a thin wrapper around Terraform that auto-injects LocalStack endpoints, so you don't have to hand-roll every override (https://github.com/localstack/terraform-local)

## Project Structure

```
terraform-static-foundations/
|-- main.tf                    # S3 bucket resource(s)
|-- variables.tf               # input variables
|-- outputs.tf                 # exposed values (bucket name, ARN, etc.)
|-- versions.tf                # Terraform + provider version constraints
|-- providers.tf               # AWS provider config (LocalStack endpoint)
|-- terraform.tfvars.example   # sample variable values - copy to terraform.tfvars
`-- README.md
```

## Getting Started

```bash
# 1. Make sure LocalStack is running
localstack start -d

# 2. Copy the example vars file and fill in your own values
cp terraform.tfvars.example terraform.tfvars

# 3. Initialize, review, apply
terraform init
terraform plan
terraform apply

# 4. Tear down when you're done
terraform destroy
```

Note on LocalStack: the AWS provider needs to be pointed at LocalStack's endpoint instead of real AWS, with dummy credentials and a few validation checks disabled. This repo's providers.tf handles that - see LocalStack's Terraform provider docs (https://docs.localstack.cloud/user-guide/integrations/terraform/) if you're configuring it from scratch.

## Variables

| Name | Description | Type | Default |
|---|---|---|---|
| environment | Deployment environment name (e.g. dev) | string | none |
| bucket_name_prefix | Prefix used to build a unique bucket name | string | none |
| tags | Common tags applied to all resources | map(string) | {} |

## Outputs

| Name | Description |
|---|---|
| bucket_name | Name of the created S3 bucket |
| bucket_arn | ARN of the created S3 bucket |

## Learning Objectives

- Configure the AWS provider to target LocalStack instead of real AWS
- Understand terraform init / plan / apply / destroy and what state represents
- Write resources driven entirely by variables - no hardcoded values
- Use outputs to expose resource attributes
- Apply consistent tagging as a baseline discipline, not an afterthought

## Status

Work in progress - first project in the Terraform learning roadmap.