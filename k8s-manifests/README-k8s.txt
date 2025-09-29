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
