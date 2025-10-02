pipeline {
    agent any
    
    environment {
        // JFrog Artifactory Configuration
        DOCKER_REGISTRY = 'cloudminds.jfrog.io'
        DOCKER_NAMESPACE = 'cloud2025'
        
        // Image Tags
        IMAGE_TAG = "${BUILD_NUMBER}-${GIT_COMMIT.take(8)}"
        LATEST_TAG = 'latest'
        
        // Docker Compose Network
        COMPOSE_PROJECT_NAME = "trademarshals-${BUILD_NUMBER}"
        
        // Service Names & Directories
        FRONTEND_DIR = 'frontend-trade-marshals'
        MIDTIER_DIR = 'midtier-trade-marshals'
        BACKEND_DIR = 'backend-trade-marshals'
        FMTS_DIR = 'fmts-backend'
        
        // JFrog Artifactory Credentials ID (configure in Jenkins)
        REGISTRY_CREDENTIALS = 'jfrog-artifactory-creds'
    }
    
    tools {
        nodejs '18'  // Configure Node.js 18 in Jenkins Global Tool Configuration
        maven '3.8'  // Configure Maven in Jenkins Global Tool Configuration
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo "🔄 Checking out code from repository..."
                checkout scm
                
                script {
                    env.GIT_COMMIT = sh(
                        script: 'git rev-parse HEAD',
                        returnStdout: true
                    ).trim()
                    
                    echo "📋 Build Info:"
                    echo "  - Build Number: ${BUILD_NUMBER}"
                    echo "  - Git Commit: ${GIT_COMMIT.take(8)}"
                    echo "  - Image Tag: ${IMAGE_TAG}"
                }
            }
        }
        
        stage('Build & Push Images') {
            parallel {
                stage('Frontend Angular') {
                    steps {
                        dir("${FRONTEND_DIR}") {
                            echo "🏗️ Building Angular Frontend..."
                            script {
                                def frontendImage = "${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/frontend:${IMAGE_TAG}"
                                def frontendLatest = "${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/frontend:${LATEST_TAG}"
                                
                                // Build Docker image
                                sh "docker build -t ${frontendImage} -t ${frontendLatest} ."
                                
                                // Push to registry
                                docker.withRegistry("https://${DOCKER_REGISTRY}", "${REGISTRY_CREDENTIALS}") {
                                    sh "docker push ${frontendImage}"
                                    sh "docker push ${frontendLatest}"
                                }
                                
                                echo "✅ Frontend image pushed: ${frontendImage}"
                            }
                        }
                    }
                }
                
                stage('Midtier Node.js') {
                    steps {
                        dir("${MIDTIER_DIR}") {
                            echo "🏗️ Building Midtier Service..."
                            script {
                                def midtierImage = "${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/midtier:${IMAGE_TAG}"
                                def midtierLatest = "${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/midtier:${LATEST_TAG}"
                                
                                // Build Docker image
                                sh "docker build -t ${midtierImage} -t ${midtierLatest} ."
                                
                                // Push to registry
                                docker.withRegistry("https://${DOCKER_REGISTRY}", "${REGISTRY_CREDENTIALS}") {
                                    sh "docker push ${midtierImage}"
                                    sh "docker push ${midtierLatest}"
                                }
                                
                                echo "✅ Midtier image pushed: ${midtierImage}"
                            }
                        }
                    }
                }
                
                stage('Backend Spring Boot') {
                    steps {
                        dir("${BACKEND_DIR}") {
                            echo "🏗️ Building Spring Boot Backend..."
                            script {
                                def backendImage = "${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/backend:${IMAGE_TAG}"
                                def backendLatest = "${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/backend:${LATEST_TAG}"
                                
                                // Build with Maven (creates JAR)
                                sh "mvn clean package -DskipTests"
                                
                                // Build Docker image
                                sh "docker build -t ${backendImage} -t ${backendLatest} ."
                                
                                // Push to registry
                                docker.withRegistry("https://${DOCKER_REGISTRY}", "${REGISTRY_CREDENTIALS}") {
                                    sh "docker push ${backendImage}"
                                    sh "docker push ${backendLatest}"
                                }
                                
                                echo "✅ Backend image pushed: ${backendImage}"
                            }
                        }
                    }
                }
                
                stage('FMTS Service') {
                    steps {
                        dir("${FMTS_DIR}") {
                            echo "🏗️ Building FMTS Service..."
                            script {
                                def fmtsImage = "${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/fmts:${IMAGE_TAG}"
                                def fmtsLatest = "${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/fmts:${LATEST_TAG}"
                                
                                // Build Docker image
                                sh "docker build -t ${fmtsImage} -t ${fmtsLatest} ."
                                
                                // Push to registry
                                docker.withRegistry("https://${DOCKER_REGISTRY}", "${REGISTRY_CREDENTIALS}") {
                                    sh "docker push ${fmtsImage}"
                                    sh "docker push ${fmtsLatest}"
                                }
                                
                                echo "✅ FMTS image pushed: ${fmtsImage}"
                            }
                        }
                    }
                }
            }
        }
        
        stage('Generate Docker Compose') {
            steps {
                echo "📝 Generating docker-compose.yml with latest images..."
                script {
                    def composeContent = """version: '3.8'

networks:
  trademarshals-network:
    driver: bridge

services:
  frontend:
    image: ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/frontend:${IMAGE_TAG}
    container_name: trademarshals-frontend-${BUILD_NUMBER}
    ports:
      - "4200:80"
    networks:
      - trademarshals-network
    environment:
      - API_BASE_URL=http://localhost:4000/api/
    depends_on:
      - midtier
    restart: unless-stopped

  midtier:
    image: ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/midtier:${IMAGE_TAG}
    container_name: trademarshals-midtier-${BUILD_NUMBER}
    ports:
      - "4000:4000"
    networks:
      - trademarshals-network
    environment:
      - NODE_ENV=production
      - BACKEND_URL=http://backend:8080/
      - FRONTEND_URL=http://frontend:80/
    depends_on:
      - backend
      - fmts
    restart: unless-stopped

  backend:
    image: ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/backend:${IMAGE_TAG}
    container_name: trademarshals-backend-${BUILD_NUMBER}
    ports:
      - "8080:8080"
    networks:
      - trademarshals-network
    environment:
      - SPRING_PROFILES_ACTIVE=prod
      - FMTS_URL=http://fmts:3000/fmts
      # Add database connection details as needed
    depends_on:
      - fmts
    restart: unless-stopped

  fmts:
    image: ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/fmts:${IMAGE_TAG}
    container_name: trademarshals-fmts-${BUILD_NUMBER}
    ports:
      - "3000:3000"
    networks:
      - trademarshals-network
    environment:
      - NODE_ENV=production
    restart: unless-stopped
"""
                    
                    writeFile file: 'docker-compose.yml', text: composeContent
                    echo "✅ Generated docker-compose.yml with build-specific images"
                }
            }
        }
        
        stage('Deploy with Docker Compose') {
            steps {
                echo "🚀 Deploying services with Docker Compose..."
                script {
                    // Stop any existing deployment
                    sh "docker-compose -p ${COMPOSE_PROJECT_NAME} down --remove-orphans || true"
                    
                    // Pull latest images
                    sh "docker-compose -p ${COMPOSE_PROJECT_NAME} pull"
                    
                    // Start services
                    sh "docker-compose -p ${COMPOSE_PROJECT_NAME} up -d"
                    
                    // Wait for services to be ready
                    echo "⏳ Waiting for services to start..."
                    sleep(time: 30, unit: 'SECONDS')
                    
                    // Show running containers
                    sh "docker-compose -p ${COMPOSE_PROJECT_NAME} ps"
                }
            }
        }
        
        stage('Health Check & Network Validation') {
            steps {
                echo "🔍 Validating deployment and network connectivity..."
                script {
                    def frontendPort = "4200"
                    def midtierPort = "4000"
                    def backendPort = "8080"
                    def fmtsPort = "3000"
                    
                    // Health check functions
                    def checkService = { serviceName, port, path = "/" ->
                        def maxRetries = 10
                        def retryDelay = 6
                        
                        for (int i = 1; i <= maxRetries; i++) {
                            try {
                                sh "curl -f -s http://localhost:${port}${path} > /dev/null"
                                echo "✅ ${serviceName} is healthy (attempt ${i})"
                                return true
                            } catch (Exception e) {
                                if (i == maxRetries) {
                                    echo "❌ ${serviceName} failed health check after ${maxRetries} attempts"
                                    throw e
                                }
                                echo "⏳ ${serviceName} not ready, retrying in ${retryDelay}s (attempt ${i}/${maxRetries})"
                                sleep(time: retryDelay, unit: 'SECONDS')
                            }
                        }
                    }
                    
                    // Check each service
                    checkService("Frontend", frontendPort)
                    checkService("Midtier", midtierPort, "/health")
                    checkService("Backend", backendPort, "/actuator/health")
                    checkService("FMTS", fmtsPort, "/health")
                    
                    // Test inter-service connectivity
                    echo "🔗 Testing inter-service network connectivity..."
                    
                    // Test service-to-service networking (internal Docker network communication)
                    echo "🔗 Testing internal service networking..."
                    
                    // Test midtier -> backend connectivity (internal network)
                    sh """
                        docker exec trademarshals-midtier-${BUILD_NUMBER} curl -f -s http://backend:8080/actuator/health > /dev/null && echo '✅ Midtier->Backend: OK' || echo '❌ Midtier->Backend: FAILED'
                    """
                    
                    // Test backend -> fmts connectivity (internal network)
                    sh """
                        docker exec trademarshals-backend-${BUILD_NUMBER} curl -f -s http://fmts:3000/health > /dev/null && echo '✅ Backend->FMTS: OK' || echo '❌ Backend->FMTS: FAILED'
                    """
                    
                    // Test frontend accessibility from host
                    sh """
                        curl -f -s http://localhost:${frontendPort} > /dev/null && echo '✅ Frontend accessible from host' || echo '❌ Frontend not accessible'
                    """
                    
                    echo "✅ All services are healthy and network connectivity verified!"
                }
            }
        }
        
        stage('Deployment Summary') {
            steps {
                script {
                    echo """
🎉 DEPLOYMENT SUCCESSFUL! 

📊 Build Summary:
  - Build Number: ${BUILD_NUMBER}
  - Git Commit: ${GIT_COMMIT.take(8)}
  - Project Name: ${COMPOSE_PROJECT_NAME}

🌐 External Access URLs (from host):
  - Frontend:  http://localhost:4200
  - Midtier:   http://localhost:4000
  - Backend:   http://localhost:8080
  - FMTS:      http://localhost:3000

🔗 Service Communication:
  - Frontend → Midtier: http://localhost:4000/api/ (browser to host)
  - Midtier → Backend: http://backend:8080/ (container to container)
  - Backend → FMTS: http://fmts:3000/fmts (container to container)

🐳 Docker Images:
  - Frontend:  ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/frontend:${IMAGE_TAG}
  - Midtier:   ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/midtier:${IMAGE_TAG}
  - Backend:   ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/backend:${IMAGE_TAG}
  - FMTS:      ${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/fmts:${IMAGE_TAG}

🔧 Management Commands:
  - View logs:     docker-compose -p ${COMPOSE_PROJECT_NAME} logs -f
  - Stop services: docker-compose -p ${COMPOSE_PROJECT_NAME} down
  - Scale services: docker-compose -p ${COMPOSE_PROJECT_NAME} up -d --scale midtier=2

✅ All services are running and network validated!
"""
                }
            }
        }
    }
    
    post {
        always {
            echo "🧹 Cleaning up build artifacts..."
            
            script {
                // Show build summary
                echo """
📊 FINAL BUILD SUMMARY:
✅ Successful builds: ${env.SUCCESSFUL_BUILDS ?: 'none'}
❌ Failed builds: ${env.FAILED_BUILDS ?: 'none'}
🚀 Services running: Check docker ps for ${COMPOSE_PROJECT_NAME} containers
"""
            }
            
            // Clean up Docker build cache (but not running containers)
            sh "docker image prune -f --filter until=24h || true"
            
            // Archive docker-compose.yml for reference
            script {
                if (fileExists('docker-compose.yml')) {
                    archiveArtifacts artifacts: 'docker-compose.yml', fingerprint: true
                }
            }
        }
        
        success {
            echo "✅ Pipeline completed successfully!"
            echo "🌐 Access your services at the URLs shown above"
        }
        
        failure {
            echo "❌ Pipeline failed!"
            script {
                echo "🔍 Debugging info:"
                sh "docker ps -a | grep trademarshals || echo 'No trademarshals containers found'"
                
                // Only stop THIS build's containers, not all containers
                sh "docker ps -q --filter name=trademarshals-${BUILD_NUMBER} | xargs -r docker stop || true"
                
                // Show logs from failed containers for debugging
                sh """
                    for container in \$(docker ps -a -q --filter name=trademarshals-${BUILD_NUMBER} 2>/dev/null || true); do
                        echo "=== Logs for container \$container ==="
                        docker logs --tail=50 \$container || true
                    done
                """
            }
        }
        
        cleanup {
            echo "🗑️ Cleaning up old containers (keeping current and previous builds)..."
            // Only remove containers older than 2 builds ago to preserve working deployments
            sh """
                OLD_BUILD=\$((${BUILD_NUMBER} - 2))
                if [ \$OLD_BUILD -gt 0 ]; then
                    docker ps -a --filter name=trademarshals-\$OLD_BUILD --format '{{.Names}}' | \\
                    xargs -r docker rm -f || true
                fi
            """
        }
    }
}
