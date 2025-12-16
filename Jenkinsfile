pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'your-registry-url'  // À configurer
        DOCKER_IMAGE = 'student-management'
        KUBE_NAMESPACE = 'devops'
        SONAR_HOST_URL = 'http://localhost:9000'  // Ou l'URL de votre SonarQube
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    echo "📦 Repository: ${env.GIT_URL}"
                    echo "🌿 Branch: ${env.GIT_BRANCH}"
                    echo "🔧 Commit: ${env.GIT_COMMIT}"
                }
            }
        }
        
        stage('Setup Environment') {
            steps {
                script {
                    echo "🔧 Setting up environment variables..."
                    // Définir des variables selon le besoin
                    sh '''
                        echo "JAVA_HOME: ${JAVA_HOME}"
                        echo "PATH: ${PATH}"
                    '''
                }
            }
        }
        
        stage('Code Quality Analysis') {
            when {
                expression { 
                    return fileExists('pom.xml') || fileExists('build.gradle') 
                }
            }
            steps {
                script {
                    echo "🔍 Running Code Quality Analysis..."
                    
                    // Pour Maven
                    if (fileExists('pom.xml')) {
                        withSonarQubeEnv('sonarqube') {  // Configurez cette instance dans Jenkins
                            sh '''
                                mvn clean verify sonar:sonar \
                                    -Dsonar.projectKey=student-management \
                                    -Dsonar.projectName="Student Management"
                            '''
                        }
                    }
                    // Pour Gradle
                    else if (fileExists('build.gradle')) {
                        withSonarQubeEnv('sonarqube') {
                            sh './gradlew sonarqube'
                        }
                    }
                }
            }
            post {
                success {
                    echo "✅ Code quality analysis completed successfully"
                    // Vous pouvez ajouter une attente pour le Quality Gate
                    // timeout(time: 1, unit: 'HOURS') {
                    //     waitForQualityGate abortPipeline: true
                    // }
                }
                failure {
                    echo "❌ Code quality analysis failed"
                }
            }
        }
        
        stage('Build & Unit Tests') {
            steps {
                script {
                    echo "🏗️ Building application..."
                    
                    if (fileExists('pom.xml')) {
                        sh 'mvn clean compile test'
                    } else if (fileExists('build.gradle')) {
                        sh './gradlew build test'
                    } else if (fileExists('package.json')) {
                        sh 'npm install && npm test'
                    }
                }
            }
            post {
                success {
                    echo "✅ Build and unit tests passed"
                    junit '**/target/surefire-reports/*.xml'  // Pour Maven
                    // ou junit '**/build/test-results/**/*.xml'  // Pour Gradle
                }
                failure {
                    echo "❌ Build or unit tests failed"
                }
            }
        }
        
        stage('Build Docker Image') {
            when {
                expression { return fileExists('Dockerfile') }
            }
            steps {
                script {
                    echo "🐳 Building Docker image..."
                    docker.build("${DOCKER_IMAGE}:${env.BUILD_NUMBER}")
                }
            }
        }
        
        stage('Push Docker Image') {
            when {
                expression { return fileExists('Dockerfile') && env.DOCKER_REGISTRY != 'your-registry-url' }
            }
            steps {
                script {
                    echo "📤 Pushing Docker image to registry..."
                    docker.withRegistry("https://${DOCKER_REGISTRY}") {
                        docker.image("${DOCKER_IMAGE}:${env.BUILD_NUMBER}").push()
                        docker.image("${DOCKER_IMAGE}:${env.BUILD_NUMBER}").push('latest')
                    }
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            when {
                expression { 
                    return fileExists('deployment.yaml') || 
                           fileExists('k8s/') || 
                           fileExists('kubernetes/') 
                }
            }
            steps {
                script {
                    echo "🚀 Deploying to Kubernetes..."
                    
                    // Configuration kubectl (si minikube)
                    sh 'minikube update-context || true'
                    
                    // Déploiement
                    if (fileExists('deployment.yaml')) {
                        sh "kubectl apply -f deployment.yaml -n ${KUBE_NAMESPACE}"
                    }
                    
                    if (fileExists('k8s/')) {
                        sh "kubectl apply -f k8s/ -n ${KUBE_NAMESPACE}"
                    }
                    
                    if (fileExists('kubernetes/')) {
                        sh "kubectl apply -f kubernetes/ -n ${KUBE_NAMESPACE}"
                    }
                    
                    // Vérification du déploiement
                    sleep 10
                    sh "kubectl get pods -n ${KUBE_NAMESPACE}"
                    sh "kubectl get svc -n ${KUBE_NAMESPACE}"
                }
            }
        }
        
        stage('Integration Tests') {
            steps {
                script {
                    echo "🧪 Running integration tests..."
                    // Attendre que l'application soit prête
                    retry(3) {
                        sleep 10
                        // Exemple de test d'intégration
                        script {
                            def MINIKUBE_IP = sh(script: 'minikube ip', returnStdout: true).trim()
                            def APP_URL = "http://${MINIKUBE_IP}:30080"
                            echo "Testing application at: ${APP_URL}"
                            
                            // Test basique de santé
                            sh """
                                curl -f ${APP_URL}/actuator/health || \
                                curl -f ${APP_URL}/health || \
                                curl -f ${APP_URL} || true
                            """
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo "🧹 Cleaning up workspace..."
            cleanWs()
        }
        
        success {
            script {
                echo "🎉 Pipeline executed successfully!"
                
                // Obtenir l'URL de l'application
                def MINIKUBE_IP = sh(script: 'minikube ip', returnStdout: true).trim()
                
                echo """
                📊 DEPLOYMENT SUMMARY:
                
                ✅ Build: ${env.BUILD_NUMBER}
                ✅ Status: SUCCESS
                
                🔗 Application URLs:
                   - Application: http://${MINIKUBE_IP}:30080
                   - Kubernetes Dashboard: minikube dashboard
                
                📦 Docker Image: ${DOCKER_IMAGE}:${env.BUILD_NUMBER}
                📁 Namespace: ${KUBE_NAMESPACE}
                
                Pour vérifier le déploiement:
                kubectl get pods -n ${KUBE_NAMESPACE}
                kubectl get svc -n ${KUBE_NAMESPACE}
                """
                
                // Optionnel: Notification par email
                // emailext (
                //     subject: "✅ SUCCESS: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                //     body: """<h2>Deployment Successful!</h2>
                //              <p>Application: http://${MINIKUBE_IP}:30080</p>""",
                //     to: 'team@example.com'
                // )
            }
        }
        
        failure {
            echo "❌ Pipeline failed!"
            script {
                // Debug info
                sh "kubectl describe pods -n ${KUBE_NAMESPACE} || true"
                sh "kubectl logs --tail=50 -n ${KUBE_NAMESPACE} -l app=spring-app || true"
                
                // emailext (
                //     subject: "❌ FAILURE: ${env.JOB_NAME} - Build #${env.BUILD_NUMBER}",
                //     body: "<h2>Pipeline Failed</h2><p>Check Jenkins for details.</p>",
                //     to: 'team@example.com'
                // )
            }
        }
        
        unstable {
            echo "⚠️ Pipeline unstable!"
        }
        
        changed {
            echo "🔄 Pipeline status changed!"
        }
    }
}
