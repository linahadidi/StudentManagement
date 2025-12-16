pipeline {
    agent any

    tools {
        maven 'M2_HOME'
        jdk 'JAVA_HOME'
    }

    stages {
        stage('1️⃣ Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/linahadidi/StudentManagement.git'
            }
        }

        stage('2️⃣ SonarQube Analysis') {
            steps {
                echo '🔍 Analyse qualité du code...'
                withSonarQubeEnv('sonarqube') {
                    sh 'mvn clean verify sonar:sonar -DskipTests'
                }
            }
        }

        stage('3️⃣ Build & Package') {
            steps {
                echo '🔨 Build application...'
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('4️⃣ Build Docker Image') {
            steps {
                echo '🐳 Construction image Docker...'
                script {
                    docker.build("linahadidi/student-app:${env.BUILD_ID}")
                }
            }
        }

        stage('5️⃣ Deploy to Kubernetes') {
            steps {
                echo '🚀 Déploiement Kubernetes...'
                sh '''
                    cat > spring-deploy.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: spring-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: spring-app
  template:
    metadata:
      labels:
        app: spring-app
    spec:
      containers:
      - name: spring-app
        image: linahadidi/student-app:${BUILD_ID}
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: spring-service
spec:
  selector:
    app: spring-app
  ports:
  - port: 8080
    targetPort: 8080
    nodePort: 30080
  type: NodePort
EOF
                    kubectl apply -f spring-deploy.yaml -n devops
                    rm spring-deploy.yaml
                '''
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline réussi!'
            sh '''
                echo "Application URL: http://$(minikube ip):30080"
                echo "SonarQube: http://localhost:9000"
            '''
        }
    }
}
