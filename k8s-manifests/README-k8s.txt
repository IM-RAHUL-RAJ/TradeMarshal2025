# Simple Angular ALB Ingress Deployment

## Overview
This setup exposes only the Angular frontend through an Application Load Balancer (ALB) using Kubernetes Ingress, while all backend services communicate internally using ClusterIP services.

## Architecture
```
Internet → ALB (Ingress) → Angular App → mid-nodejs → spring-app → fmts-nodejs
                                                    ↓
                                                   RDS
```

## Prerequisites
- EKS cluster with AWS Load Balancer Controller installed
- kubectl configured
- All services already deployed with ClusterIP

## Deployment Steps

### 1. Apply the Angular Ingress
```bash
kubectl apply -f angular-ingress.yaml
```

### 2. Update your deployments (already configured for internal communication)
```bash
kubectl apply -f angular-app-deployment.yaml
kubectl apply -f mid-nodejs-deployment.yaml
kubectl apply -f spring-app-deployment.yaml
kubectl apply -f fmts-nodejs-deployment.yaml
```

### 3. Get the ALB DNS name
```bash
kubectl get ingress angular-app-ingress
```

## Service Communication Flow
- **External Users** → ALB DNS → Angular App
- **Angular → Midtier** → `http://mid-nodejs:4000/`
- **Midtier → Backend** → `http://spring-app:8080/`
- **Backend → FMTS** → `http://fmts-nodejs:3000/fmts`
- **Backend → RDS** → Direct connection

## Testing
```bash
# Get ALB DNS
ALB_DNS=$(kubectl get ingress angular-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test Angular app
curl http://$ALB_DNS/

# Access in browser
echo "Access your app at: http://$ALB_DNS"
```

To deploy your application on EKS:

1. Apply all deployments and services:
   kubectl apply -f k8s-manifests/

2. For NodePort access to Angular frontend:
   - Service: angular-app (NodePort 31200)
   - Access: http://<any-node-ip>:31200

3. For LoadBalancer access to Angular frontend:
   - Service: angular-app-lb (external IP will be provisioned)
   - Access: http://<external-lb-ip>:4200

4. All backend services (fmts-nodejs, mid-nodejs, spring-app) are ClusterIP and accessible within the cluster by service name.

5. Remove NodePort service if you only want LoadBalancer, or vice versa.
