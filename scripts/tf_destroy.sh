#!/usr/bin/env bash
set -euo pipefail
ROOT="terraform/kubernetes"
ENV="${1:-dev}"
cd "$ROOT"
terraform init
terraform destroy -auto-approve -var-file="envs/${ENV}.tfvars"
