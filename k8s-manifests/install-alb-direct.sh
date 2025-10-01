#!/bin/bash

# Direct AWS Load Balancer Controller Installation for K8s 1.32
# This works when the EKS add-on is not available

set -e

echo "Installing AWS Load Balancer Controller for Kubernetes 1.32..."

# Get cluster info
CLUSTER_NAME=$(kubectl config current-context | cut -d'/' -f2)
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region)

echo "Cluster: $CLUSTER_NAME"
echo "Account: $AWS_ACCOUNT_ID"
echo "Region: $AWS_REGION"

# Step 1: Download and create IAM policy
echo "Creating IAM policy..."
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json \
    --region $AWS_REGION 2>/dev/null || echo "Policy already exists"

# Step 2: Create service account with IAM role
echo "Creating service account..."
eksctl create iamserviceaccount \
  --cluster=$CLUSTER_NAME \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::$AWS_ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve \
  --region $AWS_REGION || echo "Service account already exists"

# Step 3: Install cert-manager
echo "Installing cert-manager..."
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.13.0/cert-manager.yaml

echo "Waiting for cert-manager to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s

# Step 4: Install AWS Load Balancer Controller
echo "Installing AWS Load Balancer Controller..."
curl -Lo v2_7_2_full.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.7.2/v2_7_2_full.yaml

# Replace cluster name
sed -i.bak "s/your-cluster-name/$CLUSTER_NAME/g" v2_7_2_full.yaml

# Remove ServiceAccount section since we created it with eksctl
sed -i.bak2 '/---/,$!d' v2_7_2_full.yaml

kubectl apply -f v2_7_2_full.yaml

# Step 5: Wait for deployment
echo "Waiting for AWS Load Balancer Controller to be ready..."
kubectl wait --for=condition=available deployment/aws-load-balancer-controller -n kube-system --timeout=300s

echo "✅ AWS Load Balancer Controller installed successfully!"
echo ""
echo "Now you can apply your ingress:"
echo "kubectl apply -f angular-ingress.yaml"
echo ""
echo "Verify installation:"
echo "kubectl get pods -n kube-system | grep aws-load-balancer-controller"

# Cleanup
rm -f iam_policy.json v2_7_2_full.yaml v2_7_2_full.yaml.bak v2_7_2_full.yaml.bak2
