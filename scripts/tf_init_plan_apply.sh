#!/usr/bin/env bash
set -euo pipefail
ROOT="terraform/kubernetes"
ENV="${1:-dev}"

cd "$ROOT"
terraform init
terraform plan -var-file="envs/${ENV}.tfvars" -out "plan-${ENV}.tfplan"
terraform apply -auto-approve "plan-${ENV}.tfplan"
