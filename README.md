# sports-store-infrastructure

Terraform infrastructure-as-code for the AWS resources backing the Sports
Store platform: VPC/networking, Amazon EKS, and Amazon ECR. Provisioned in
**Stage 5A — AWS Infrastructure with Terraform** of the CloudCart DevOps final
lab. No application workloads are deployed by this repo — that's Stage 5B, in
`sports-store-deployments`.

## Layout

| File | Purpose |
|---|---|
| `versions.tf` | Terraform/provider version constraints, Terraform Cloud workspace config |
| `providers.tf` | AWS provider configuration |
| `variables.tf` | All configurable inputs |
| `locals.tf` | Derived naming/AZ locals |
| `vpc.tf` | VPC, public/private subnets, NAT Gateway, subnet tagging (`terraform-aws-modules/vpc/aws`) |
| `eks.tf` | EKS control plane, managed node group, IRSA, cluster add-ons (`terraform-aws-modules/eks/aws`) |
| `ecr.tf` | One ECR repository per component + lifecycle policy |
| `outputs.tf` | Cluster/VPC/ECR outputs consumed by Stage 5B |

## Prerequisites

- Terraform >= 1.7
- An AWS account with credentials available to Terraform Cloud (Task 2)
- A Terraform Cloud account/org

## Terraform Cloud setup (Task 2)

This repo uses TFC's **VCS-driven workflow** — pushes to `main` and PR branches
trigger remote plans automatically; applies run in Terraform Cloud, not on a
laptop, and state is stored/locked remotely.

1. Create a Terraform Cloud account at https://app.terraform.io if you don't
   have one, and an organization (e.g. `cloudcart-iitc`).
2. In the org, create a new workspace:
   - Workflow type: **Version control workflow**.
   - Connect to GitHub, select the `IITC-College/sports-store-infrastructure`
     repo.
   - Workspace name: `sports-store-infrastructure` (must match the
     `workspaces { name = ... }` block in `versions.tf`).
   - Terraform working directory: `/` (repo root — this *is* the Terraform
     root module).
3. Under workspace **Variables**, add:
   - Environment variables (mark sensitive): `AWS_ACCESS_KEY_ID`,
     `AWS_SECRET_ACCESS_KEY` (and `AWS_SESSION_TOKEN` if using temporary
     credentials).
   - Terraform variables: any overrides to the defaults in `variables.tf`
     (region, cluster size, etc. — see `terraform.tfvars.example`).
4. If `versions.tf`'s `cloud { organization = "..." }` doesn't match your org
   name, update it and push — VCS-driven plans won't trigger until it does.
5. Push a commit / open a PR against `main`: TFC auto-triggers a **speculative
   plan** on the PR and a **real plan** (awaiting apply) on merge to `main`.
   Confirm the apply in the TFC UI (or auto-apply, if the workspace is
   configured that way).

**Terraform state is never committed to this repository** — it lives entirely
in the TFC workspace, with locking enabled by default.

## Local development

```bash
terraform fmt -recursive
terraform init    # uses the `cloud` block — logs in to TFC, no local state
terraform validate
terraform plan     # runs remotely in TFC even from a local `plan`
```

## After apply

`enable_cluster_creator_admin_permissions` grants EKS cluster-admin to
whoever *ran* apply — with the VCS-driven TFC workflow, that's the OIDC
execution role (`tfc-sports-store-infrastructure`), not a human. Anyone who
needs `kubectl` from their own machine has to grant themselves an access
entry first (one-time, per IAM principal):

```bash
aws eks create-access-entry --cluster-name "$(terraform output -raw cluster_name)" \
  --principal-arn "$(aws sts get-caller-identity --query Arn --output text)" --type STANDARD
aws eks associate-access-policy --cluster-name "$(terraform output -raw cluster_name)" \
  --principal-arn "$(aws sts get-caller-identity --query Arn --output text)" \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster

$(terraform output -raw configure_kubectl)
kubectl get nodes
kubectl get pods -n kube-system
```

Cluster/VPC/ECR details are available via `terraform output` for Stage 5B to
consume (`ecr_repository_urls`, `cluster_name`, `cluster_oidc_provider_arn`,
etc).

## Teardown

This provisions real, billable AWS resources (EKS control plane, NAT
Gateway(s), EC2 worker nodes). When not actively using the cluster:

```bash
terraform destroy
```

ECR repositories are created with `force_delete = true`, so `destroy` removes
them even if they still contain images (this is a lab environment that gets
torn down/recreated often — don't carry this into a real production repo).
