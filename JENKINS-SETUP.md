# Jenkins Pipeline Setup Guide

## What This Pipeline Does

This Jenkins pipeline is a **Groovy-based declarative pipeline script** (`Jenkinsfile`) that automates the complete CI/CD process for Trade Marshals application:

1. **Checkout**: Pulls latest code from your Git repository
2. **Parallel Docker Builds**: Builds all 4 services simultaneously:
   - Frontend (Angular) → `cloudminds.jfrog.io/cloud2025/frontend:build-tag`
   - Midtier (Node.js) → `cloudminds.jfrog.io/cloud2025/midtier:build-tag`
   - Backend (Spring Boot) → `cloudminds.jfrog.io/cloud2025/backend:build-tag`
   - FMTS (Node.js) → `cloudminds.jfrog.io/cloud2025/fmts:build-tag`
3. **Push to JFrog**: Uploads images to `cloudminds.jfrog.io/cloud2025/`
4. **Generate Docker Compose**: Creates deployment config with correct image tags
5. **Deploy & Test**: Runs all services with Docker networking and validates connectivity

**Final Result**: Working application accessible at:
- Frontend: http://localhost:4200 (host access)
- Midtier API: http://localhost:4000 (host access)  
- Backend: http://localhost:8080 (host access)
- FMTS: http://localhost:3000 (host access)

**Service Communication Patterns**:
- **Frontend → Midtier**: `http://localhost:4000/api/` (browser-based, uses host network)
- **Midtier → Backend**: `http://backend:8080/` (server-to-server, Docker internal network)
- **Backend → FMTS**: `http://fmts:3000/fmts` (server-to-server, Docker internal network)

**Jenkins vs Application Ports**:
- Jenkins UI: http://localhost:9090 (avoids conflict with Backend:8080)
- Application uses original ports: 4200, 4000, 8080, 3000

---

## Option 1: Run Jenkins in Docker (Recommended)

### Step 1: Create Jenkins Docker Setup

```bash
# Create Jenkins workspace directory
mkdir -p ~/jenkins-data
chmod 777 ~/jenkins-data

# Run Jenkins with Docker support (using port 9090 to avoid conflict)
docker run -d \
  --name jenkins-trademarshals \
  -p 9090:8080 \
  -p 50000:50000 \
  -v ~/jenkins-data:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $(which docker):/usr/bin/docker \
  --group-add=$(stat -c %g /var/run/docker.sock) \
  jenkins/jenkins:lts

# Get initial admin password
docker exec jenkins-trademarshals cat /var/jenkins_home/secrets/initialAdminPassword
```

### Step 2: Initial Jenkins Configuration

1. Open http://localhost:9090
2. Enter the admin password from above
3. Install suggested plugins + these additional ones:
   - Docker Pipeline
   - NodeJS Plugin
   - Maven Integration Plugin
   - Git Plugin

### Step 3: Configure Tools in Jenkins

Go to **Manage Jenkins → Global Tool Configuration**:

**Node.js Installations:**
- Name: `18`
- Version: `NodeJS 18.x` (install automatically)

**Maven Installations:**
- Name: `3.8`
- Version: `3.8.6` (install automatically)

---

## Step 4: Configure Credentials

Go to **Manage Jenkins → Manage Credentials → Global**:

### JFrog Artifactory Credentials
- Kind: `Username with password`
- ID: `jfrog-artifactory-creds`
- Username: `your-jfrog-username`
- Password: `LA2025fmr`

### Git Credentials (if private repo)
- Kind: `Username with password` or `SSH Username with private key`
- ID: `git-repo-creds`
- Username: `your-git-username`
- Password: `your-git-token`

---

## Step 5: Create Pipeline Job

1. **New Item** → **Pipeline**
2. **Name**: `TradeMarshal-CI-CD`
3. **Pipeline Definition**: `Pipeline script from SCM`
4. **SCM**: `Git`
5. **Repository URL**: `https://github.com/IM-RAHUL-RAJ/TradeMarshal2025.git`
6. **Credentials**: Select your git credentials (if private)
7. **Branch**: `*/main`
8. **Script Path**: `Jenkinsfile`

---

## Option 2: Install Jenkins Directly (Alternative)

### Ubuntu/Debian Installation:
```bash
# Install Java 11
sudo apt update
sudo apt install openjdk-11-jdk -y

# Add Jenkins repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt update
sudo apt install jenkins -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker jenkins

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Get initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### CentOS/RHEL Installation:
```bash
# Install Java 11
sudo yum install java-11-openjdk-devel -y

# Add Jenkins repository
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key

# Install Jenkins
sudo yum install jenkins -y

# Install Docker
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker jenkins

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Get initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

---

## Running the Pipeline

1. Go to your pipeline job
2. Click **Build Now**
3. Monitor progress in **Console Output**
4. After successful build, access services:
   - Frontend: http://localhost:4200
   - API: http://localhost:4000
   - Backend: http://localhost:8080
   - FMTS: http://localhost:3000

---

## Pipeline Stages Explained

| Stage | What It Does | Duration |
|-------|-------------|----------|
| Checkout | Downloads code from Git | ~30s |
| Build & Push Images | Builds 4 Docker images in parallel | ~5-10min |
| Generate Docker Compose | Creates deployment config | ~10s |
| Deploy with Docker Compose | Starts all services | ~1-2min |
| Health Check | Validates all services running | ~1min |

**Total Runtime**: ~8-15 minutes

---

## Troubleshooting

### Build Fails - Docker Permission
```bash
# Fix Docker permissions for Jenkins user
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### JFrog Authentication Fails
- Verify credentials in Jenkins
- Test manually: `docker login cloudminds.jfrog.io`

### Port Conflicts
```bash
# Check what's using ports
sudo netstat -tulpn | grep -E ':(4200|4000|8080|3000)'

# Stop conflicting services
docker-compose down
```

### Pipeline Fails at Maven Build
- Check if Maven 3.8 is configured in Global Tool Configuration
- Verify `pom.xml` exists in backend directory

---

## Next Steps After This Pipeline

This pipeline stops at Docker deployment. For Kubernetes:
1. Use the images pushed to JFrog: `cloudminds.jfrog.io/cloud2025/service:tag`
2. Update K8s manifests with new image tags
3. Apply with `kubectl apply -f k8s-manifests/`
4. Use the ALB controller script we created earlier

The pipeline provides a solid foundation for local/staging testing before Kubernetes production deployment.



<!-- password-1928c7a43e0140fdbc6d90bdb71f4ad1 -->
<!-- username- a900001
password - LA2025fmr -->
