#!/usr/bin/env bash

# install-aws-load-balancer-controller.sh
# Purpose: Idempotent installer for AWS Load Balancer Controller (ALB Ingress Controller)
# Usage: ./scripts/install-aws-load-balancer-controller.sh -c <cluster-name> -r <region> [-v <vpc-id>] [-p <policy-name>] [-n <namespace>]
# Requires: aws, kubectl, helm, jq, (eksctl OR aws iam + kubectl)

set -euo pipefail

DEFAULT_NAMESPACE="kube-system"
POLICY_NAME_DEFAULT="AWSLoadBalancerControllerIAMPolicy"
CHART_VERSION="1.7.2"   # Update as needed
REPO_NAME="eks"
REPO_URL="https://aws.github.io/eks-charts"
SERVICE_ACCOUNT="aws-load-balancer-controller"

CLUSTER_NAME=""
REGION=""
VPC_ID=""
POLICY_NAME="$POLICY_NAME_DEFAULT"
NAMESPACE="$DEFAULT_NAMESPACE"

usage() {
  grep '^#' "$0" | sed 's/^# //'
  exit 1
}

while getopts 'c:r:v:p:n:h' flag; do
  case "$flag" in
    c) CLUSTER_NAME="$OPTARG" ;;
    r) REGION="$OPTARG" ;;
    v) VPC_ID="$OPTARG" ;;
    p) POLICY_NAME="$OPTARG" ;;
    n) NAMESPACE="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

if [[ -z "${CLUSTER_NAME}" ]]; then
  # Try to infer from current context (EKS contexts usually: arn:aws:eks:<region>:<acct>:cluster/<name>)
  CURRENT_CTX=$(kubectl config current-context 2>/dev/null || true)
  CLUSTER_NAME=${CURRENT_CTX##*/}
  echo "[INFO] Inferred cluster name: $CLUSTER_NAME" >&2
fi

if [[ -z "${REGION}" ]]; then
  # Try to parse from current context ARN style
  CURRENT_CTX=$(kubectl config current-context 2>/dev/null || true)
  REGION=$(echo "$CURRENT_CTX" | awk -F: '/eks/{print $4}' || true)
  [[ -z "$REGION" ]] && { echo "[ERROR] Region not supplied (-r) and could not infer." >&2; exit 1; }
  echo "[INFO] Inferred region: $REGION" >&2
fi

command -v aws >/dev/null || { echo "[ERROR] aws CLI not found" >&2; exit 1; }
command -v kubectl >/dev/null || { echo "[ERROR] kubectl not found" >&2; exit 1; }
command -v helm >/dev/null || { echo "[ERROR] helm not found" >&2; exit 1; }
command -v jq >/dev/null || { echo "[ERROR] jq not found" >&2; exit 1; }

echo "[INFO] Validating cluster access..."
kubectl get nodes >/dev/null

echo "[INFO] Ensuring OIDC provider for cluster..."
OIDC_URL=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" --query 'cluster.identity.oidc.issuer' --output text)
OIDC_HOST=${OIDC_URL#*//}
if aws iam list-open-id-connect-providers | grep -q "$OIDC_HOST"; then
  echo "[INFO] OIDC provider already exists." 
else
  if command -v eksctl >/dev/null; then
    echo "[INFO] Creating OIDC provider via eksctl" 
    eksctl utils associate-iam-oidc-provider --cluster "$CLUSTER_NAME" --region "$REGION" --approve
  else
    echo "[ERROR] OIDC provider missing and eksctl not installed. Install eksctl or create provider manually." >&2
    exit 1
  fi
fi

echo "[INFO] Ensuring IAM policy $POLICY_NAME exists..."
POLICY_ARN="arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/$POLICY_NAME"
if ! aws iam get-policy --policy-arn "$POLICY_ARN" >/dev/null 2>&1; then
  echo "[INFO] Creating IAM policy $POLICY_NAME"
  TMPF=$(mktemp)
  curl -fsSL https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json -o "$TMPF"
  aws iam create-policy --policy-name "$POLICY_NAME" --policy-document file://"$TMPF" >/dev/null
fi

echo "[INFO] Creating/ensuring service account with IAM role..."
if command -v eksctl >/dev/null; then
  eksctl create iamserviceaccount \
    --cluster "$CLUSTER_NAME" \
    --region "$REGION" \
    --namespace "$NAMESPACE" \
    --name "$SERVICE_ACCOUNT" \
    --attach-policy-arn "$POLICY_ARN" \
    --approve \
    --override-existing-serviceaccounts || true
else
  echo "[WARN] eksctl not found; assuming service account already handled. If not, manually create IAM role and annotate SA." >&2
fi

echo "[INFO] Adding Helm repo $REPO_NAME if needed..."
if ! helm repo list | grep -q "\b$REPO_NAME\b"; then
  helm repo add "$REPO_NAME" "$REPO_URL"
fi
helm repo update >/dev/null

echo "[INFO] Installing / upgrading AWS Load Balancer Controller chart..."
helm upgrade -i aws-load-balancer-controller $REPO_NAME/aws-load-balancer-controller \
  -n "$NAMESPACE" \
  --set clusterName="$CLUSTER_NAME" \
  --set region="$REGION" \
  --set serviceAccount.create=false \
  --set serviceAccount.name="$SERVICE_ACCOUNT" \
  --version "$CHART_VERSION"

echo "[INFO] Waiting for deployment rollout..."
kubectl rollout status deployment/aws-load-balancer-controller -n "$NAMESPACE" --timeout=180s

echo "[INFO] Installed. Validate with: kubectl get ingressclasses; kubectl get ingress"
echo "[INFO] To uninstall: helm uninstall aws-load-balancer-controller -n $NAMESPACE (service account/IAM role remain)."
