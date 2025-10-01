# AWS Load Balancer Controller Installation Guide

The ingress is not creating an ALB because the AWS Load Balancer Controller is not installed in your EKS cluster.

## Quick Installation Steps:

### Manual Installation (Required for Kubernetes 1.32)

Since you're running Kubernetes 1.32, the EKS add-on is not available. Use this manual installation:

#### Quick Installation:
```bash
# Make the script executable and run
chmod +x install-alb-direct.sh
./install-alb-direct.sh
```

#### Manual Step-by-Step (if script fails):
```bash
# 1. Get cluster info
CLUSTER_NAME=$(kubectl config current-context | cut -d'/' -f2)
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# 2. Create IAM policy
curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.7.2/docs/install/iam_policy.json
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json

# 3. Create service account with IAM role
eksctl create iamserviceaccount \
  --cluster=$CLUSTER_NAME \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::$AWS_ACCOUNT_ID:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve

# 4. Install cert-manager
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# 5. Wait for cert-manager
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s

# 6. Install AWS Load Balancer Controller
curl -Lo v2_7_2_full.yaml https://github.com/kubernetes-sigs/aws-load-balancer-controller/releases/download/v2.7.2/v2_7_2_full.yaml
sed -i "s/your-cluster-name/$CLUSTER_NAME/g" v2_7_2_full.yaml
kubectl apply -f v2_7_2_full.yaml
```

## After Installation:

1. **Verify the controller is running:**
```bash
kubectl get pods -n kube-system | grep aws-load-balancer-controller
```

2. **Delete and recreate the ingress:**
```bash
kubectl delete ingress angular-app-ingress
kubectl apply -f angular-ingress.yaml
```

3. **Check ingress status:**
```bash
kubectl get ingress angular-app-ingress
# Should show ADDRESS field populated after 2-3 minutes
```

4. **Get ALB DNS:**
```bash
kubectl get ingress angular-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

## Troubleshooting:

If the ingress still shows `*` in HOSTS after installation:
1. Check controller logs: `kubectl logs -n kube-system deployment/aws-load-balancer-controller`
2. Ensure your EKS cluster has proper IAM permissions
3. Check if subnets are properly tagged for ALB discovery

The ingress should create an ALB within 2-3 minutes after the controller is properly installed.
