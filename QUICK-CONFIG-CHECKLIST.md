# Quick Configuration Checklist- [ ] Create Pipeline Job
- [ ] New Item > Pipeline > Name: `Your-App-Local-Test`
- [ ] Pipeline script from SCM
- [ ] Git repository: `https://github.com/YOUR-USERNAME/YOUR-REPO`
- [ ] Branch: `*/your-branch`
- [ ] Script Path: `Jenkinsfile-local`

## 🔄 Understanding Jenkinsfile-local Pipeline Steps

### Pipeline Overview
The `Jenkinsfile-local` creates a complete CI/CD pipeline that builds and deploys your multi-service application using Docker containers. Here's what happens in each stage:

### Stage 1: 🧹 Cleanup
```groovy
// What it does:
- Stops and removes any existing containers from previous deployments
- Removes unused Docker networks to prevent conflicts
- Ensures clean environment for new deployment
```
**Purpose**: Prevents port conflicts and ensures fresh deployment state

### Stage 2: 🔧 Setup Environment 
```groovy
// What it does:
- Creates custom Docker network 'tradeapp-network' for service communication
- Sets environment variables for container naming and ports
- Validates Docker is available and working
```
**Purpose**: Establishes isolated network for your application services to communicate

### Stage 3: �️ Build Services (Parallel)
This stage runs 4 builds simultaneously to save time:

#### Frontend Build
```groovy
// What it does:
1. Changes to frontend directory (e.g., frontend-trade-marshals/)
2. Runs: docker build -t trademarshals/frontend:latest .
3. Uses Angular Dockerfile with Node.js 20
4. Installs npm dependencies and builds production Angular app
5. Creates nginx-served static files
```

#### Midtier Build  
```groovy
// What it does:
1. Changes to midtier directory (e.g., midtier-trade-marshals/)
2. Runs: docker build -t trademarshals/midtier:latest .
3. Uses Node.js 18 base image
4. Installs npm dependencies
5. Builds TypeScript API server
```

#### Backend Build
```groovy
// What it does:
1. Changes to backend directory (e.g., backend-trade-marshals/)  
2. Runs: docker build -t trademarshals/backend:latest .
3. Uses OpenJDK 11 with Maven
4. Downloads dependencies, compiles Java code
5. Creates executable Spring Boot JAR
```

#### FMTS Build
```groovy
// What it does:
1. Changes to FMTS directory (e.g., fmts-backend/)
2. Runs: docker build -t trademarshals/fmts:latest .
3. Uses Node.js 18 base image
4. Installs npm dependencies for trading system
```

### Stage 4: 🚀 Deploy Services (Sequential)
Services are deployed in dependency order:

#### 1. Backend Deployment
```groovy
docker run -d --name spring-app --network tradeapp-network \
  -p 8080:8080 --dns=8.8.8.8 trademarshals/backend:latest
```
**What it does**:
- Creates backend container named 'spring-app'
- Maps port 8080 (host) to 8080 (container)
- Adds DNS for external database connectivity
- Connects to shared network for inter-service communication

#### 2. FMTS Deployment  
```groovy
docker run -d --name fmts-nodejs --network tradeapp-network \
  -p 3000:3000 trademarshals/fmts:latest
```
**What it does**:
- Creates FMTS service container
- Maps port 3000 for trading functionality
- Connects to shared network

#### 3. Midtier Deployment
```groovy
docker run -d --name mid-nodejs --network tradeapp-network \
  -p 4000:4000 trademarshals/midtier:latest  
```  
**What it does**:
- Creates API gateway/middleware container
- Maps port 4000 for API endpoints
- Can communicate with backend via network using 'spring-app:8080'

#### 4. Frontend Deployment
```groovy
docker run -d --name angular-app --network tradeapp-network \
  -p 4200:80 trademarshals/frontend:latest
```
**What it does**:
- Creates web server container (nginx)
- Maps port 4200 (host) to 80 (nginx default)
- Serves Angular app to browsers
- Makes API calls to midtier at 'localhost:4000'

### Stage 5: ✅ Health Checks
```groovy
// What it does:
1. Waits 30 seconds for services to start
2. Checks each service endpoint:
   - Frontend: http://localhost:4200 (expects HTTP 200)
   - Midtier: http://localhost:4000/health (expects response)  
   - Backend: http://localhost:8080/actuator/health (Spring Boot health)
3. Reports which services are healthy/unhealthy
4. Pipeline succeeds only if all services pass health checks
```

### Stage 6: 📊 Deployment Summary
```groovy
// What it does:
- Lists all running containers with status and ports
- Shows service URLs for testing
- Provides troubleshooting commands
- Displays next steps for manual testing
```

### Key Pipeline Features:

1. **Parallel Builds**: All 4 services build simultaneously (saves ~60% time)
2. **Network Isolation**: Services communicate via custom Docker network  
3. **Health Validation**: Automatic testing ensures deployment success
4. **Error Handling**: Pipeline fails fast if any step fails
5. **Clean Environment**: Always starts with clean state
6. **Port Management**: Maps container ports to host for external access

### Environment Variables Set:
- `DOCKER_NAMESPACE`: Prefix for all Docker images (e.g., 'trademarshals')
- `FRONTEND_DIR`: Frontend source directory  
- `MIDTIER_DIR`: Midtier source directory
- `BACKEND_DIR`: Backend source directory
- `FMTS_DIR`: FMTS source directory

## 📝 Step-by-Step ChangesBefore Starting
- [ ] Install Docker and Docker Compose
- [ ] Set up Jenkins with required plugins  
- [ ] Identify your application's service architecture
- [ ] Note all service ports and names used in code
- [ ] Get database connection details

## 🏗️ Jenkins Setup (One-time)

### 1. Install Jenkins
```bash
# Quick Docker setup
docker run -d --name jenkins-trademarshals -p 9090:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home -v /var/run/docker.sock:/var/run/docker.sock \
  -v /usr/bin/docker:/usr/bin/docker --group-add $(stat -c %g /var/run/docker.sock) \
  jenkins/jenkins:lts
```

### 2. Initial Configuration
- [ ] Access Jenkins at `http://localhost:9090`
- [ ] Get password: `docker exec jenkins-trademarshals cat /var/jenkins_home/secrets/initialAdminPassword`
- [ ] Install suggested plugins + Docker Pipeline plugin
- [ ] Create admin user

### 3. Configure Tools (Manage Jenkins > Tools)
- [ ] **Maven**: Name: `3.8`, Auto-install: ✅, Version: `3.8.6`
- [ ] **NodeJS**: Name: `18`, Auto-install: ✅, Version: `NodeJS 18.17.0`
- [ ] **Docker**: Name: `docker`, Auto-install: ✅, Version: `latest`

### 4. Create Pipeline Job
- [ ] New Item > Pipeline > Name: `Your-App-Local-Test`
- [ ] Pipeline script from SCM
- [ ] Git repository: `https://github.com/YOUR-USERNAME/YOUR-REPO`
- [ ] Branch: `*/your-branch`
- [ ] Script Path: `Jenkinsfile-local`

## 📝 Step-by-Step Changes

### 1. Jenkinsfile-local Updates
```diff
- DOCKER_NAMESPACE = 'trademarshals'
+ DOCKER_NAMESPACE = 'your-app-name'

- FRONTEND_DIR = 'frontend-trade-marshals'
+ FRONTEND_DIR = 'your-frontend-folder'

- MIDTIER_DIR = 'midtier-trade-marshals'  
+ MIDTIER_DIR = 'your-midtier-folder'

- BACKEND_DIR = 'backend-trade-marshals'
+ BACKEND_DIR = 'your-backend-folder'

- -p 4200:80    # Frontend port
+ -p YOUR_PORT:80

- -p 4000:4000  # Midtier port  
+ -p YOUR_PORT:4000

- -p 8080:8080  # Backend port
+ -p YOUR_PORT:8080

- --name spring-app     # Backend container name
+ --name your-backend-service-name

- --name mid-nodejs     # Midtier container name  
+ --name your-midtier-service-name

- --name angular-app    # Frontend container name
+ --name your-frontend-service-name
```

### 2. Database Configuration
**File**: `backend/src/main/resources/application-prod.properties`
```diff
- spring.datasource.url=jdbc:oracle:thin:@trade-marshals-db.cj6ui28e0bu9.ap-south-1.rds.amazonaws.com:1521/ORCL
+ spring.datasource.url=jdbc:oracle:thin:@YOUR-RDS-HOSTNAME:1521/ORCL

- spring.datasource.username=admin
+ spring.datasource.username=YOUR_USERNAME

- spring.datasource.password=SR2024fmr  
+ spring.datasource.password=YOUR_PASSWORD
```

### 3. Frontend API URLs
**File**: `frontend/src/environments/environment.ts`
```diff
- apiBaseUrl: 'http://localhost:4000/'
+ apiBaseUrl: 'http://localhost:YOUR_MIDTIER_PORT/'
```

### 4. Midtier Service URLs  
**File**: `midtier/src/constants.ts`
```diff
- BACKEND_URL: 'http://spring-app:8080/',
+ BACKEND_URL: 'http://your-backend-service-name:YOUR_PORT/',
```

### 5. Health Check Ports
**File**: `Jenkinsfile-local` (around line 380)
```diff
- case 'frontend': port = "4200"; break
+ case 'frontend': port = "YOUR_FRONTEND_PORT"; break

- case 'midtier': port = "4000"; break
+ case 'midtier': port = "YOUR_MIDTIER_PORT"; break

- case 'backend': port = "8080"; break  
+ case 'backend': port = "YOUR_BACKEND_PORT"; break
```

## 🧪 Testing Commands

```bash
# 1. Test database hostname resolution
nslookup YOUR-RDS-HOSTNAME

# 2. Search for hardcoded service names in your code
grep -r "spring-app\|mid-nodejs\|angular-app" your-code/

# 3. Check for hardcoded ports
grep -r ":4200\|:4000\|:8080\|:3000" your-code/

# 4. After deployment, verify services
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

# 5. Test API connectivity  
curl http://localhost:YOUR_MIDTIER_PORT/health
curl http://localhost:YOUR_BACKEND_PORT/actuator/health
```

## ⚠️ Common Gotchas

1. **Service Names**: Your application code must expect the container names you set
2. **Port Conflicts**: Check no other services use your chosen ports  
3. **DNS**: Backend needs `--dns=8.8.8.8` if connecting to external databases
4. **Network**: All containers must be on same Docker network for inter-service communication
5. **Case Sensitivity**: Service names are case-sensitive in Docker networks

## 🚀 Deploy & Test

### 1. Pre-deployment Validation
```bash
# Test configuration files
# Check if service names exist in code
grep -r "your-service-names" your-code/

# Test database connectivity
nslookup your-rds-hostname
telnet your-rds-hostname 1521

# Check port availability
netstat -tulpn | grep -E ':YOUR_PORTS'
```

### 2. Deploy
```bash
# 1. Commit your changes
git add .
git commit -m "Configure for new application"
git push

# 2. Run Jenkins pipeline
# Go to Jenkins > Your-Job > Build Now
# Or trigger manually with webhook
```

### 3. Monitor Deployment
```bash
# Watch Jenkins build logs in real-time
# Jenkins > Your-Job > Build #X > Console Output

# Monitor Docker containers
watch docker ps

# Check specific service logs
docker logs -f your-frontend-container
docker logs -f your-midtier-container  
docker logs -f your-backend-container
```

### 4. Validate Deployment
```bash
# Check all services are running
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

# Test frontend
curl -I http://localhost:YOUR_FRONTEND_PORT
open http://localhost:YOUR_FRONTEND_PORT

# Test API endpoints
curl http://localhost:YOUR_MIDTIER_PORT/health
curl http://localhost:YOUR_BACKEND_PORT/actuator/health

# Test end-to-end functionality
# (e.g., login, API calls, database operations)
```

### 5. Cleanup (if needed)
```bash
# Stop all containers
docker stop $(docker ps -q --filter name=your-app)

# Remove containers
docker rm $(docker ps -aq --filter name=your-app)

# Remove networks
docker network prune

# Remove unused images
docker image prune
```

## 📞 Need Help?

Check the full `DEPLOYMENT-CONFIG-GUIDE.md` for detailed explanations and troubleshooting tips!
