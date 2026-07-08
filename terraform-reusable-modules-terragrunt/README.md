# Terraform Reusable Modules — Terragrunt Variant

The same storage/database modules and dev/qa/prod environments as [`terraform-reusable-modules`](../terraform-reusable-modules/README.md), rebuilt with Terragrunt to eliminate the per-environment boilerplate that plain Terraform required.

## Why this exists

In the plain-Terraform version, `environments/dev`, `qa`, and `prod` each carried the same six files (`versions.tf`, `providers.tf`, `variables.tf`, `locals.tf`, `main.tf`, `outputs.tf`) plus a `terraform.tfvars` pair — byte-identical except for the tfvars values. Terragrunt removes that duplication:

| | Plain Terraform | Terragrunt |
|---|---|---|
| Provider + version config | Repeated in every environment | Written once in `root.hcl`, `generate`d into every unit automatically |
| Module call (`main.tf`) | Hand-written per environment | Not needed — `terraform { source = "..." }` points straight at the module |
| Outputs (`outputs.tf`) | Hand-written per environment | Not needed — the module's own outputs pass through directly |
| Naming/tagging logic (`locals.tf`) | Repeated per environment | Computed once in `root.hcl`, read via each environment's one-line `env.hcl` |
| Files per environment | 8 (6 duplicated `.tf` files + 2 `.tfvars`) | 3 (`env.hcl` + 2 small `terragrunt.hcl` files) |

## Architecture

```
                    +---------------------------+
                    |      modules/storage        |
                    +---------------------------+
                              ^
    +------------------------+------------------------+
    |                        |                         |
+---------+            +---------+              +----------+
|   dev    |            |   qa     |              |   prod    |
+---------+            +---------+              +----------+
    |                        |                         |
    +------------------------+------------------------+
                              v
                    +---------------------------+
                    |     modules/database         |
                    +---------------------------+
```

Each environment/component pair (e.g. `dev/storage`, `dev/database`) is an independent Terragrunt "unit" with its own state — six units total, run together with `terragrunt run-all`.

## Project Structure

```
terraform-reusable-modules-terragrunt/
|-- root.hcl                        # generates provider.tf + versions.tf, computes name_prefix/common_tags
|-- environments/
|   |-- dev/
|   |   |-- env.hcl                 # locals { environment = "dev" }
|   |   |-- storage/terragrunt.hcl  # include root, source = modules/storage, inputs
|   |   `-- database/terragrunt.hcl # include root, source = modules/database, inputs
|   |-- qa/     (same shape, env.hcl says "qa")
|   `-- prod/   (same shape, env.hcl says "prod")
|-- modules/
|   |-- storage/    (identical to the plain-Terraform version)
|   `-- database/   (identical to the plain-Terraform version)
`-- README.md
```

## Prerequisites

- Terraform >= 1.5, Terragrunt >= 1.1 (both managed here via [tenv](https://github.com/tofuutils/tenv))
- Docker + LocalStack running locally

## Getting Started

Terragrunt 1.1's `run --all -- <cmd>` replaces the "cd into each environment folder" workflow from the plain-Terraform version. Use `--provider-cache` — with 6 units initializing the same AWS provider in parallel, Terraform's plain shared plugin cache (`~/.terraformrc`'s `plugin_cache_dir`) can race and leave a unit with a lock-file/checksum mismatch; Terragrunt's built-in provider cache server coordinates this correctly:

```bash
# From environments/, applies all 3 environments x 2 components (6 units) in one command
cd environments
terragrunt run --all --provider-cache -- init
terragrunt run --all --provider-cache -- plan
terragrunt run --all --provider-cache -- apply -auto-approve

# Or scope to just one environment
cd dev
terragrunt run --all --provider-cache -- apply -auto-approve

# Tear down
cd environments
terragrunt run --all --provider-cache -- destroy -auto-approve
```

Note: local state here lives inside each unit's `.terragrunt-cache/<hash>/<hash>/terraform.tfstate` (Terragrunt copies the module source into a cache dir per unit before running). That's fine as long as the `generate` blocks in `root.hcl` don't change between runs — if they do, the cache-dir hash changes and a fresh, stateless copy is used. A real project would point this at a remote backend (S3, covered in Project 5) instead of relying on local state surviving in an ephemeral cache directory.

Verify in LocalStack:
```bash
aws --endpoint-url=http://localhost:4566 s3 ls
aws --endpoint-url=http://localhost:4566 dynamodb list-tables
```

## What's identical to the plain-Terraform version

- `modules/storage` and `modules/database` — the actual resource logic is untouched
- Resulting resource names (`urlshortener-dev-assets`, `urlshortener-dev-urls`, etc.)
- The `billing_mode` validation inside `modules/database` still runs the same way

## What's different

- No `variable "environment" { validation { ... } }` guardrail — under this layout, the environment is fixed by which folder you're in (`env.hcl`), not a free-text input that could be mistyped into a shared `.tfvars` file
- State is split per-component (6 states) rather than per-environment (3 states)

## Status

Work in progress - Terragrunt variant of Project 2, built to see the DRY pattern the guide calls out as future work (Project 6).
