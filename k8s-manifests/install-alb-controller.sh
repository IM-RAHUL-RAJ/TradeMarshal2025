#!/bin/bash

# AWS Load Balancer Controller Installation for EKS
# Run these commands step by step

echo "Installing AWS Load Balancer Controller..."

# Step 1: Get your cluster name and AWS account ID
CLUSTER_NAME=$(kubectl config current-context | cut -d'/' -f2)
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=$(aws configure get region)

echo "Cluster Name: $CLUSTER_NAME"
echo "AWS Account: $AWS_ACCOUNT_ID" 
echo "AWS Region: $AWS_REGION"

# Step 2: Download IAM policy for AWS Load Balancer Controller
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json

# Step 3: Create IAM policy (ignore if already exists)
aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json || echo "Policy already exists, continuing..."

# Step 4: Create IAM role and service account
eksctl create iamserviceaccount \
  --cluster=$CLUSTER_NAME \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::$AWS_ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

# Step 5: Install cert-manager (required for webhook certificates)
kubectl apply \
    --validate=false \
    -f https://github.com/jetstack/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager to be ready
echo "Waiting for cert-manager to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s

# Step 6: Install AWS Load Balancer Controller
curl -Lo v2_7_2_full.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.7.2/v2_7_2_full.yaml

# Replace cluster name in the YAML
sed -i.bak -e "s|your-cluster-name|$CLUSTER_NAME|" v2_7_2_full.yaml

# Remove the ServiceAccount section (we created it with eksctl)
kubectl apply -f v2_7_2_full.yaml

# Step 7: Verify installation
echo "Verifying AWS Load Balancer Controller installation..."
kubectl get deployment -n kube-system aws-load-balancer-controller

echo "AWS Load Balancer Controller installation completed!"
echo "Now you can apply your ingress: kubectl apply -f angular-ingress.yaml"
