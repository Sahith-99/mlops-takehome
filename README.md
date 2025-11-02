# 🧭 MLOps Take-Home Assessment — Cluster Audit Automation

This project provisions an **Amazon EKS cluster** using Terraform, builds and pushes a custom **cluster audit image** to **Amazon ECR**, and deploys a **Kubernetes CronJob** that periodically audits the cluster and stores the output.

---

## 🏗️ Project Overview

The objective of this assessment is to:
1. Provision an EKS cluster via Terraform.
2. Build and publish the **cluster-audit** container image to ECR.
3. Deploy a **Kubernetes Job / CronJob** that audits cluster resources (nodes, pods, namespaces, etc.) and writes results to `/output`.
4. Integrate the entire workflow via **GitHub Actions** for automated CI/CD.

---

## 🧩 Architecture Overview

```
Developer → GitHub Actions → Terraform (EKS) → ECR → EKS Cluster
                               │
                               ├── EKS Nodes run cluster-audit job
                               │
                               └── CronJob schedules periodic audits
```

**Core Components:**
- **Terraform** — Provisions multi-environment Kubernetes (EKS).
- **ECR** — Stores container images for the cluster.
- **Kubernetes CronJob** — Runs hourly to audit and log cluster state.
- **GitHub Actions** — Manages CI/CD pipeline for Terraform + Docker + K8s deploy.

---

## 🗂️ Repository Structure

```bash
.
├── Dockerfile
├── README.md
├── .github/
│   └── workflows/
│       └── cicd.yml
├── kubernetes/
│   ├── audit-job.yaml
│   ├── audit-cronjob.yaml
│   └── rbac.yaml
├── output/
│   └── .gitkeep
├── scripts/
│   ├── kubeconfig_from_eks.sh
│   ├── tf_init_plan_apply.sh
│   └── tf_destroy.sh
├── src/
│   └── cluster_audit/
│       ├── cluster_audit.py
│       └── requirements.txt
└── terraform/
    └── kubernetes/
        ├── backend.tf
        ├── main.tf
        ├── providers.tf
        ├── variables.tf
        ├── versions.tf
        ├── outputs.tf
        ├── envs/
        │   ├── dev.tfvars
        │   ├── stg.tfvars
        │   └── prod.tfvars
        └── modules/
            └── eks-cluster/
                ├── main.tf
                ├── outputs.tf
                └── variables.tf
```

---

## ⚙️ Setup Instructions

### 1️⃣ Clone and Initialize
```bash
git clone https://github.com/<your-org>/mlops-takehome.git
cd mlops-takehome
```

### 2️⃣ Terraform — Provision Cluster
```bash
cd terraform/kubernetes
terraform init
terraform plan -var-file="envs/dev.tfvars"
terraform apply -auto-approve
```

### 3️⃣ Configure Kubectl
```bash
./scripts/kubeconfig_from_eks.sh <cluster_name> <region> kubeconfig
export KUBECONFIG=$(pwd)/kubeconfig
```

### 4️⃣ Build & Push Docker Image
```bash
REGION=us-east-1
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REPO_URI="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/cluster-audit"

docker buildx build   --platform linux/amd64   -t "$REPO_URI:latest"   --push .
```

### 5️⃣ Deploy the CronJob
```bash
kubectl apply -f kubernetes/audit-cronjob.yaml
kubectl get pods
kubectl logs -l job-name=cluster-audit --tail=50
```

---

## 💡 Usage Examples

### Run Audit On-Demand
```bash
kubectl apply -f kubernetes/audit-job.yaml
kubectl logs -l job-name=cluster-audit
```

### Verify Audit Output
```bash
kubectl get pods
kubectl cp <pod_name>:/output ./output
cat ./output/cluster_audit_<timestamp>.json
```

---

## 🧰 Troubleshooting Guide

| Issue | Possible Cause | Resolution |
|-------|----------------|-------------|
| **`ErrImagePull`** | Image not found in ECR | Ensure ECR repo exists and image tag pushed correctly |
| **`Forbidden` error (403)** | ServiceAccount lacks RBAC | Apply `kubernetes/rbac.yaml` to grant access |
| **Pod stuck in `Pending`** | Node resources exhausted | Check node group scaling, retry job |
| **Terraform state conflict** | Locked backend | Release DynamoDB state lock or re-init |

---

## ⚡ GitHub Actions CI/CD Workflow

Located at `.github/workflows/cicd.yml`

### Stages
1. **Terraform Init & Apply**
2. **Docker Build & ECR Push**
3. **Kubernetes Deploy**
4. **Job Verification via kubectl logs**

Triggered on:
- Push to `main`
- Manual `workflow_dispatch`

---

## 📁 Example terraform.tfvars Files

### `dev.tfvars`
```hcl
environment = "dev"
region      = "us-east-1"
cluster_name = "eks-dev-cluster"
node_instance_type = "t3.medium"
desired_capacity = 2
```

### `stg.tfvars`
```hcl
environment = "stg"
region      = "us-east-1"
cluster_name = "eks-stg-cluster"
node_instance_type = "t3.large"
desired_capacity = 3
```

### `prod.tfvars`
```hcl
environment = "prod"
region      = "us-east-1"
cluster_name = "eks-prod-cluster"
node_instance_type = "m5.large"
desired_capacity = 4
```

---

## 🔍 Sample kubectl Verification Commands

```bash
kubectl get nodes -o wide
kubectl get pods -A
kubectl get jobs -A
kubectl describe job cluster-audit
kubectl logs -l job-name=cluster-audit
kubectl get cronjobs
kubectl get events --sort-by=.metadata.creationTimestamp | tail -20
```

---

## 🧠 Design Decisions & Assumptions

- **Multi-Environment Support:** Terraform is modular, supporting `dev`, `stg`, and `prod` via `tfvars`.
- **Security:** Uses RBAC and ECR-based private image access.
- **Portability:** Uses `docker buildx` to ensure cross-platform builds (`linux/amd64`).
- **Resilience:** The CronJob is idempotent — completed pods terminate cleanly.
- **Observability:** Logs are written to `/output` and can be exported to CloudWatch in future enhancements.

---

## 🧾 .gitignore Recommendations

```gitignore
# Terraform
*.tfstate
*.tfstate.backup
*.tfplan

# Output
/output/*
!output/.gitkeep

# kubeconfig
terraform/kubernetes/kubeconfig

# Python cache
__pycache__/
*.pyc

# IDE / OS
.DS_Store
.vscode/
.idea/
```

---
