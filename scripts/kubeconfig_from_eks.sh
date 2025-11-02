#!/usr/bin/env bash
set -euo pipefail
CLUSTER_NAME="$1"
REGION="${2:-us-east-1}"
OUT="${3:-kubeconfig}"

aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION" --kubeconfig "$OUT"
echo "Wrote kubeconfig to $OUT"
echo "To export for kubectl: export KUBECONFIG=$(pwd)/$OUT"
