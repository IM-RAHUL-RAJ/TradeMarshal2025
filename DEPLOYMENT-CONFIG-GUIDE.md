# Docker Deployment Configuration Guide

This guide explains how to set up Jenkins and adapt the Jenkins-local pipeline and code configuration for different applications based on the Trade Marshals setup.

## 📋 Overview

The current setup deploys a 4-tier application:
- **Frontend**: Angular application (port 4200)
- **Midtier**: Node.js API service (port 4000)  
- **Backend**: Spring Boot API service (port 8080)
- **FMTS**: Node.js financial service (port 3000)
- **Database**: Oracle RDS

## 🏗️ Initial Jenkins Setup

### 1. **Install Jenkins**

#### Option A: Docker Installation (Recommended)
```bash
# Create Jenkins container with Docker access
docker run -d \
  --name jenkins-trademarshals \
  -p 9090:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /usr/bin/docker:/usr/bin/docker \
  --group-add $(stat -c %g /var/run/docker.sock) \
  jenkins/jenkins:lts
```

#### Option B: Native Installation
```bash
# Ubuntu/Debian
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update
sudo apt install jenkins

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

### 2. **Access Jenkins**
- **URL**: `http://localhost:9090` (or `http://localhost:8080` for native install)
- **Initial Password**: 
  ```bash
  # For Docker
  docker exec jenkins-trademarshals cat /var/jenkins_home/secrets/initialAdminPassword
  
  # For Native
  sudo cat /var/lib/jenkins/secrets/initialAdminPassword
  ```

### 3. **Install Required Plugins**

#### Essential Plugins (Install during setup wizard):
- [x] **Pipeline**: Pipeline plugin suite
- [x] **Git**: Git integration
- [x] **GitHub**: GitHub integration  
- [x] **Docker Pipeline**: Docker integration
- [x] **Build Timeout**: Timeout builds
- [x] **Timestamper**: Add timestamps to logs
- [x] **Workspace Cleanup**: Clean workspace

#### Additional Plugins (Install via Manage Jenkins > Plugins):
```
1. Go to: Manage Jenkins > Plugins > Available Plugins
2. Search and install:
   - "Docker Pipeline"
   - "NodeJS Plugin" 
   - "Maven Integration"
   - "Pipeline: Stage View"
   - "Blue Ocean" (optional, for better UI)
   - "Credentials Binding"
```

### 4. **Configure Tools**

#### Go to: Manage Jenkins > Tools

#### **Maven Configuration**:
- Name: `3.8`
- Install automatically: ✅
- Version: `3.8.6`

#### **NodeJS Configuration**:
- Name: `18`
- Install automatically: ✅  
- Version: `NodeJS 18.17.0`

#### **Docker Configuration**:
- Name: `docker`
- Install automatically: ✅
- Version: `latest`

### 5. **Create Pipeline Job**

#### Step-by-Step:
1. **New Item** > **Pipeline** > Enter name: `TradeMarshal-Local-Test`
2. **Pipeline Configuration**:
   - Definition: `Pipeline script from SCM`
   - SCM: `Git`
   - Repository URL: `https://github.com/YOUR-USERNAME/YOUR-REPO`
   - Branch: `*/feature/jenkins-docker-compose` (or your branch)
   - Script Path: `Jenkinsfile-local`
3. **Build Triggers**: (Optional)
   - [x] Poll SCM: `H/5 * * * *` (every 5 minutes)
   - [x] GitHub hook trigger for GITScm polling
4. **Save**

### 6. **Configure Credentials (If Private Repo)**

#### Go to: Manage Jenkins > Credentials > System > Global credentials
1. **Add Credentials**:
   - Kind: `Username with password`
   - Username: Your Git username
   - Password: Your Personal Access Token
   - ID: `github-credentials`
   - Description: `GitHub Access`

2. **Update Pipeline**:
   - In job configuration, under SCM
   - Credentials: Select your created credentials

### 7. **Environment Prerequisites**

#### Ensure System Has:
```bash
# Docker (with Docker Compose)
docker --version          # Should be 20.10+
docker compose version    # Should work

# Git
git --version             # Should be 2.0+

# Port Availability
netstat -tulpn | grep -E ':4200|:4000|:8080|:3000|:9090'  # Should be free
```

## 🔧 Pipeline Customization for Your Application

### 1. **Fork/Copy the Repository Structure**
```bash
# Clone the base repository
git clone https://github.com/IM-RAHUL-RAJ/TradeMarshal2025.git your-app-name
cd your-app-name

# Create your branch
git checkout -b feature/your-app-deployment
```

## 🔧 Configuration Changes Required

### 1. **Application Names & Ports**

#### File: `Jenkinsfile-local`
```groovy
// Lines 6-7: Update Docker namespace
DOCKER_NAMESPACE = 'your-app-name'

// Lines 18-21: Update service directories
FRONTEND_DIR = 'your-frontend-folder'
MIDTIER_DIR = 'your-midtier-folder' 
BACKEND_DIR = 'your-backend-folder'
FMTS_DIR = 'your-service-folder'        // Optional: Remove if not needed
```

#### Port Mappings (Lines 295-350):
```groovy
// Frontend
-p 4200:80          // Change 4200 to your desired frontend port

// Midtier  
-p 4000:4000        // Change 4000 to your midtier port

// Backend
-p 8080:8080        // Change 8080 to your backend port

// FMTS (Optional)
-p 3000:3000        // Change 3000 to your service port or remove
```

### 2. **Service Names & Container Names**

#### Current Service Names (must match your code expectations):
```groovy
// Lines 295-350: Container names that your application code expects
--name fmts-nodejs      // Change to your service name
--name spring-app       // Change to your backend service name  
--name mid-nodejs       // Change to your midtier service name
--name angular-app      // Change to your frontend service name
```

#### Check Your Code For Service References:
1. **Backend → Other Services**: Search for service names in backend configuration
2. **Midtier → Backend**: Check `src/constants.ts` or similar config files
3. **Frontend → Midtier**: Check environment files

### 3. **Database Configuration**

#### File: `backend/src/main/resources/application-prod.properties`
```properties
# Update RDS hostname
spring.datasource.url=jdbc:oracle:thin:@YOUR-RDS-HOSTNAME:1521/ORCL
spring.datasource.username=YOUR_DB_USERNAME
spring.datasource.password=YOUR_DB_PASSWORD
```

#### File: `backend/src/main/resources/application-dev.properties`
```properties
# Same changes as prod if using same database
spring.datasource.url=jdbc:oracle:thin:@YOUR-RDS-HOSTNAME:1521/ORCL
```

#### For Different Database Types:
```properties
# PostgreSQL
spring.datasource.url=jdbc:postgresql://YOUR-HOST:5432/YOUR_DB
spring.datasource.driver-class-name=org.postgresql.Driver

# MySQL  
spring.datasource.url=jdbc:mysql://YOUR-HOST:3306/YOUR_DB
spring.datasource.driver-class-name=com.mysql.cj.jdbc.Driver

# H2 (Local testing)
spring.datasource.url=jdbc:h2:mem:testdb
spring.datasource.driver-class-name=org.h2.Driver
```

### 4. **API URLs & Service Communication**

#### Frontend Configuration:
File: `frontend/src/environments/environment.ts`
```typescript
export const environment = {
  production: false,
  apiBaseUrl: 'http://localhost:YOUR_MIDTIER_PORT/'  // Change port
};
```

File: `frontend/src/environments/environment.prod.ts`
```typescript
export const environment = {
  production: true,
  apiBaseUrl: 'http://localhost:YOUR_MIDTIER_PORT/'  // Change port
};
```

#### Midtier Configuration:
File: `midtier/src/constants.ts`
```typescript
const defaultConfig = {
  FRONTEND_URL: 'http://localhost:YOUR_FRONTEND_PORT',
  BACKEND_URL: 'http://YOUR-BACKEND-SERVICE-NAME:YOUR_BACKEND_PORT/',
};
```

#### Backend Configuration (if calling other services):
Search your backend code for hardcoded service URLs and update them.

### 5. **Docker Compose Generation (Optional)**

#### File: `Jenkinsfile-local` (Lines 190-270)
Update the docker-compose.yml generation section with your service configurations:

```groovy
// Update service definitions
if (env.SUCCESSFUL_BUILDS.contains('your-service')) {
    composeContent += """
  your-service:
    image: ${DOCKER_NAMESPACE}/your-service:${IMAGE_TAG}
    container_name: your-service-name-${BUILD_NUMBER}
    ports:
      - "YOUR_PORT:CONTAINER_PORT"
    networks:
      - trademarshals-network
    environment:
      - YOUR_ENV_VARS=values
    depends_on:
      - other-service
    restart: unless-stopped
"""
}
```

### 6. **Health Check URLs**

#### File: `Jenkinsfile-local` (Lines 375-395)
```groovy
// Update port numbers for health checks
switch(service) {
    case 'frontend': port = "YOUR_FRONTEND_PORT"; break
    case 'midtier': port = "YOUR_MIDTIER_PORT"; break  
    case 'backend': port = "YOUR_BACKEND_PORT"; break
    case 'your-service': port = "YOUR_SERVICE_PORT"; break
}
```

## 🗂️ File Structure Expected

```
your-project/
├── Jenkinsfile-local
├── your-frontend-folder/
│   ├── Dockerfile
│   ├── src/environments/
│   └── ...
├── your-midtier-folder/
│   ├── Dockerfile  
│   ├── src/constants.ts
│   └── ...
├── your-backend-folder/
│   ├── Dockerfile
│   ├── src/main/resources/
│   │   ├── application.properties
│   │   ├── application-prod.properties
│   │   └── application-dev.properties
│   └── ...
└── your-optional-service-folder/
    ├── Dockerfile
    └── ...
```

## 🚀 Deployment Steps

### 1. **Update All Configuration Files**
- [ ] Update `Jenkinsfile-local` with new service names, ports, directories
- [ ] Update database configuration files
- [ ] Update API URLs in frontend and midtier
- [ ] Update service names in application code

### 2. **Test Configuration**
```bash
# Test database connectivity
nslookup YOUR-RDS-HOSTNAME

# Test if application expects correct service names
grep -r "service-name" your-code/
```

### 3. **Build & Deploy**
```bash
# Run Jenkins pipeline
# Or manually build:
docker build -t your-app/frontend:tag ./your-frontend-folder
docker build -t your-app/midtier:tag ./your-midtier-folder  
docker build -t your-app/backend:tag ./your-backend-folder
```

### 4. **Verify Deployment**
- [ ] Check all containers are running: `docker ps`
- [ ] Test frontend: `http://localhost:YOUR_FRONTEND_PORT`
- [ ] Test API endpoints: `curl http://localhost:YOUR_MIDTIER_PORT/health`
- [ ] Check logs: `docker logs container-name`

## 🛠️ Troubleshooting

### Jenkins Setup Issues:

#### **Problem**: Jenkins won't start
```bash
# Check if port is in use
sudo netstat -tulpn | grep :9090

# Check Docker container status
docker ps -a | grep jenkins

# Check logs
docker logs jenkins-trademarshals
```

#### **Problem**: Jenkins can't access Docker
```bash
# Fix Docker socket permissions
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins

# For Docker container setup
docker exec -u root jenkins-trademarshals chown root:docker /var/run/docker.sock
```

#### **Problem**: Maven/NodeJS not found
- Go to: Manage Jenkins > Tools
- Ensure automatic installation is enabled
- Check tool names match pipeline configuration

#### **Problem**: Git authentication fails
- Create Personal Access Token in GitHub
- Add credentials in Jenkins: Manage Jenkins > Credentials
- Update pipeline job to use credentials

### Application Deployment Issues:

#### **Problem**: Service Name Mismatch
```bash
# Check your code for hardcoded service names
grep -r "spring-app\|mid-nodejs\|angular-app" your-code/
```

#### **Problem**: Port Conflicts
```bash
# Check what's using your ports
sudo netstat -tulpn | grep -E ':4200|:4000|:8080|:3000'

# Kill processes if needed
sudo fuser -k 4200/tcp
```

#### **Problem**: Database Connection Issues  
```bash
# Test RDS hostname resolution
nslookup your-rds-hostname

# Check backend logs
docker logs your-backend-container

# Test database connectivity from container
docker exec backend-container telnet your-rds-host 1521
```

#### **Problem**: Container Communication Issues
```bash
# Check container network
docker inspect container-name --format '{{range $net, $v := .NetworkSettings.Networks}}{{$net}} {{end}}'

# Test inter-container connectivity
docker exec container1 wget -qO- http://container2:port/endpoint

# Check DNS resolution
docker exec container nslookup service-name
```

### Debug Commands:
```bash
# Jenkins pipeline debugging
# Check workspace
docker exec jenkins-trademarshals ls -la /var/jenkins_home/workspace/

# Check build artifacts  
docker exec jenkins-trademarshals ls -la /var/jenkins_home/workspace/YOUR-JOB-NAME/

# Application debugging
# Check all containers
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

# Check network connectivity
docker network ls
docker network inspect your-network-name

# Check logs for all services
docker logs frontend
docker logs midtier  
docker logs backend
docker logs your-service
```

## 📝 Checklist for New Application

- [ ] Update `DOCKER_NAMESPACE` in Jenkinsfile-local
- [ ] Update service directory names  
- [ ] Update all port mappings
- [ ] Update container names to match code expectations
- [ ] Update database configuration (hostname, credentials)
- [ ] Update API URLs in frontend/midtier
- [ ] Update service names in constants/config files
- [ ] Update health check ports
- [ ] Test database connectivity
- [ ] Remove unused services (like FMTS if not needed)
- [ ] Update docker-compose generation section
- [ ] Test complete deployment flow

## 🔗 Key Files to Modify

1. `Jenkinsfile-local` - Main deployment pipeline
2. `*/src/environments/*.ts` - Frontend API URLs
3. `*/src/constants.ts` - Midtier service URLs  
4. `*/src/main/resources/application*.properties` - Backend database config
5. `*/Dockerfile` - If ports or configurations need changes

This configuration supports any multi-tier application with similar architecture!
