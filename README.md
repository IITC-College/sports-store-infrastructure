# sports-store-infrastructure

Terraform infrastructure-as-code for the AWS resources backing the Sports
Store platform (EKS, ECR, networking, and related cloud infra).

Populated starting **Stage 5A — AWS Infrastructure with Terraform** of the
CloudCart DevOps final lab. Empty scaffold as of Stage 1 (project setup).
## Branching Strategy

- `main` — protected, always deployable. Direct pushes are disabled; all
  changes land via pull request with at least one approval.
- `feature/<short-description>` — new features, branched from `main`.
- `bugfix/<short-description>` — non-urgent fixes, branched from `main`.
- `hotfix/<short-description>` — urgent production fixes, branched from
  `main`, merged back via PR as soon as verified.

Open a PR against `main` when a branch is ready for review. At least one
approval is required before merging.
