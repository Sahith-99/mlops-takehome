<<<<<<< HEAD
# Senior MLOps Take-home – EKS, CI/CD, Kubernetes Audit

This repo delivers a reusable EKS Terraform module for **dev/stg/prod**, a GitLab CI pipeline, and a Python-based **cluster audit** container deployed as a CronJob.

## Contents
- `terraform/kubernetes`: Root Terraform for EKS
- `terraform/kubernetes/modules/eks-cluster`: Reusable module (VPC, subnets, NAT, IAM, SG, EKS + NodeGroups, logging)
- `src/cluster_audit`: Python audit tool (lists nodes, pods, warnings → JSON)
- `kubernetes/`: Job + CronJob manifests for the audit image
- `.gitlab-ci.yml`: Validate → Plan → Apply/Destroy → Build/Push → Deploy
- `scripts/`: Helper scripts
- `output/`: Local audit output

---

## Architecture Overview

**Networking**
- Single VPC with **public** and **private** subnets across AZs
- IGW + NAT GW, public RT for Internet egress, private RT via NAT

**Security**
- Separate SG for cluster and nodes
- Node SG allows east-west inside VPC, egress to Internet

**IAM**
- Cluster role: `AmazonEKSClusterPolicy`, `AmazonEKSVpcResourceController`
- Node role: `AmazonEKSWorkerNodePolicy`, `AmazonEC2ContainerRegistryReadOnly`, `AmazonEKS_CNI_Policy`
- OIDC provider created for future IRSA

**EKS**
- Control plane logs enabled by default
- Managed Node Groups per environment (size & instance types configurable)

**Audit**
- Python container lists cluster state and writes a timestamped JSON report.
- Run as a **CronJob** hourly or as an ad-hoc **Job**.

---

## Prerequisites

- Terraform ≥ 1.6
- AWS credentials with permissions for VPC/EKS/IAM if you plan to `apply`
- `kubectl` (optional for local verification and audit deployment)
- (Optional for CI) GitLab project & container registry

> Note: The AWS provider block includes mock creds to allow `terraform validate/plan` without real AWS creds. For actual `apply`, export valid AWS credentials and (optionally) edit `providers.tf` to remove mock values.

---

## Quickstart (Local)

```bash
# 1) Enter terraform root
cd terraform/kubernetes

# 2) Initialize and validate
terraform init
terraform validate

# 3) Plan for dev
terraform plan -var-file="envs/dev.tfvars" -out dev.tfplan

# 4) Apply (requires working AWS credentials)
terraform apply dev.tfplan
```

### Get kubeconfig & verify
```bash
../../scripts/kubeconfig_from_eks.sh mlops-platform-dev-eks us-east-1 kubeconfig
export KUBECONFIG=$(pwd)/kubeconfig
kubectl get nodes -o wide
```

### Run audit as a Job or CronJob
- Build locally:
```bash
docker build -t cluster-audit:local .
kubectl apply -f kubernetes/audit-job.yaml
kubectl logs -l job-name=cluster-audit --all-containers
```
- Or schedule hourly:
```bash
kubectl apply -f kubernetes/audit-cronjob.yaml
```

---

## CI/CD (GitLab)

**Stages**
1. **Validate**: Terraform fmt/validate; Python security scan (bandit)
2. **Test**: Terraform plan for dev/stg/prod
3. **Infrastructure**: manual `apply` and `destroy` (requires `TARGET_ENV` variable)
4. **Deploy**: Build/push `cluster_audit` image; optional manual K8s deploy using a base64 kubeconfig

**Required CI variables**
- `CI_REGISTRY_USER`, `CI_REGISTRY_PASSWORD`
- `KUBECONFIG_B64` (optional, for deploy stage)

---

## Example kubectl commands for verification

```bash
kubectl get nodes
kubectl get pods -A
kubectl get events -A --sort-by=.lastTimestamp | tail -n 20
```

---

## Assumptions & Design Decisions

- Opinionated but production-style VPC + EKS layout that’s easy to extend.
- Node groups on private subnets.
- Control plane logging on for observability.
- Reusable module to drive dev/stg/prod via `*.tfvars`.

---

## Submission

Create a **public** repo (GitLab preferred). Push these files, then email the repo link to:
`DL-DPDATA-DataScience-ML-Ops@charter.com`.
=======
# initial page
>>>>>>> db0f8e70fe8bc82d621de040db42b6b2d23a6fbe
