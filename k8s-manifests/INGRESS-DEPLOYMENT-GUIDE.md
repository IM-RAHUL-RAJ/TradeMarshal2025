# Trade Marshals Ingress Deployment Guide

## Prerequisites
1. EKS cluster should be running
2. kubectl configured to connect to your cluster
3. Helm installed

## Step-by-Step Deployment

### 1. Install AWS Load Balancer Controller
```bash
# Make the script executable
chmod +x install-alb-controller.sh

# Update the cluster name in the script before running
sed -i 's/your-cluster-name/YOUR_ACTUAL_CLUSTER_NAME/g' install-alb-controller.sh

# Run the installation script
./install-alb-controller.sh
```

### 2. Deploy ClusterIP Services
```bash
kubectl apply -f cluster-ip-services.yaml
```

### 3. Deploy Applications
```bash
kubectl apply -f deployments-ingress.yaml
```

### 4. Deploy Ingress (Choose one option)

#### Option A: Path-based routing (Recommended for development)
```bash
kubectl apply -f ingress.yaml
```

#### Option B: Host-based routing (Recommended for production)
```bash
kubectl apply -f ingress-hosts.yaml
```

### 5. Get ALB DNS Name
```bash
kubectl get ingress trade-marshals-ingress
# OR for host-based
kubectl get ingress trade-marshals-ingress-hosts
```

### 6. Update Angular Environment Configuration
After getting the ALB DNS name, update your Angular app:

For path-based routing:
```typescript
export const environment = {
  production: true,
  apiBaseUrl: 'http://<ALB_DNS_NAME>/api/'
};
```

For host-based routing:
```typescript
export const environment = {
  production: true,
  apiBaseUrl: 'http://api.trademarshals.com/'
};
```

### 7. Rebuild and Redeploy Angular App
```bash
# Rebuild Angular with new environment
cd frontend-trade-marshals
ng build --prod

# Build new Docker image
docker build -t rahulrvc.jfrog.io/rahul-repo/a900001/frontend-a900001:ingress .

# Push to registry
docker push rahulrvc.jfrog.io/rahul-repo/a900001/frontend-a900001:ingress

# Update deployment with new image
kubectl set image deployment/angular-app angular-app=rahulrvc.jfrog.io/rahul-repo/a900001/frontend-a900001:ingress
```

## Testing the Ingress Setup

### Test Frontend
```bash
curl http://<ALB_DNS_NAME>/
```

### Test API Endpoints
```bash
# Test midtier health
curl http://<ALB_DNS_NAME>/api/

# Test registration
curl -X POST http://<ALB_DNS_NAME>/api/client/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"Test123","name":"Test User","dateOfBirth":"1990-01-01","country":"India","identification":[{"type":"PAN","value":"ABCDE1234F"}]}'
```

### Test FMTS
```bash
curl http://<ALB_DNS_NAME>/fmts/trades/prices
```

## Benefits of Ingress over Multiple LoadBalancers
1. **Cost Reduction**: Single ALB instead of 4 separate LoadBalancers
2. **Centralized SSL/TLS**: Manage certificates in one place
3. **Better Routing**: Path/host-based routing capabilities
4. **Simplified DNS**: Single entry point for all services

## Cleanup Old LoadBalancer Services
After confirming ingress works:
```bash
kubectl delete -f angular-app-lb-service.yaml
kubectl delete -f mid-nodejs-lb-service.yaml
kubectl delete -f spring-app-lb-service.yaml
kubectl delete -f fmts-nodejs-lb-service.yaml
```
