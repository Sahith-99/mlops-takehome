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
│   └── audit-cronjob.yaml
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

## ⚙️ scripts/

| Script | Purpose | Usage |
|---------|----------|--------|
| `kubeconfig_from_eks.sh` | Generate kubeconfig for EKS | `./scripts/kubeconfig_from_eks.sh <cluster> <region> <output-file>` |
| `tf_init_plan_apply.sh` | (Optional) Local Terraform automation | For local debugging |
| `tf_destroy.sh` | (Optional) Destroy Terraform-managed resources | For cleanup |

> Only `kubeconfig_from_eks.sh` is typically required for standard operations.

---

## ⚡ GitHub Actions CI/CD

Located at `.github/workflows/cicd.yml`

### Pipeline Stages
1. **Terraform Apply**
2. **Build & Push Docker Image**
3. **Deploy to EKS**
4. **Verify Job Logs**

### Trigger:
- On push or PR to `main`
- Manual trigger (`workflow_dispatch`)

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

## 🏁 Deliverables Checklist

✅ EKS cluster deployed via Terraform  
✅ ECR image built & pushed  
✅ Cluster-audit CronJob runs hourly  
✅ Logs and JSON audit output generated  
✅ CI/CD workflow integrated

---
