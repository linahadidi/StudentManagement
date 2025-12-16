pipeline {
    agent any

    tools {
        maven 'M2_HOME'
        jdk 'JAVA_HOME'
    }

    environment {
        // Configuration SonarQube
        SONAR_HOST_URL = 'http://192.168.49.2:9000'  // ou localhost si Jenkins et SonarQube sur même machine
        SONAR_PROJECT_KEY = 'student-management'
        SONAR_PROJECT_NAME = 'Student Management'
    }

    stages {

        stage('1️⃣ Clone Repository') {
            steps {
                echo '📥 Clonage du projet...'
                git branch: 'main', url: 'https://github.com/linahadidi/StudentManagement.git'
                echo '✅ Repository cloné'
            }
        }

        stage('2️⃣ Créer projet SonarQube via API') {
            steps {
                echo '🔧 Création automatique du projet dans SonarQube...'
                script {
                    // Générer un token admin temporaire si besoin
                    // Note: Tu dois d'abord créer un token admin manuellement une fois
                    // et le mettre dans Jenkins Credentials avec l'ID 'sonarqube-admin-token'
                    
                    withCredentials([string(credentialsId: 'sonarqube-admin-token', variable: 'SONAR_ADMIN_TOKEN')]) {
                        // Vérifier si le projet existe déjà
                        def projectExists = sh(
                            script: """
                                curl -s -o /dev/null -w "%{http_code}" \
                                -u "${SONAR_ADMIN_TOKEN}:" \
                                "${SONAR_HOST_URL}/api/projects/search?projects=${SONAR_PROJECT_KEY}"
                            """,
                            returnStdout: true
                        ).trim()
                        
                        // Créer le projet s'il n'existe pas
                        if (projectExists != "200") {
                            echo "Création du projet ${SONAR_PROJECT_KEY} dans SonarQube..."
                            sh """
                                curl -X POST \
                                -u "${SONAR_ADMIN_TOKEN}:" \
                                "${SONAR_HOST_URL}/api/projects/create?name=${SONAR_PROJECT_NAME}&project=${SONAR_PROJECT_KEY}&visibility=public"
                            """
                            echo "✅ Projet créé dans SonarQube"
                        } else {
                            echo "✅ Le projet existe déjà dans SonarQube"
                        }
                        
                        // Générer un token pour l'analyse
                        def scanToken = sh(
                            script: """
                                curl -X POST \
                                -u "${SONAR_ADMIN_TOKEN}:" \
                                "${SONAR_HOST_URL}/api/user_tokens/generate?name=jenkins-scan-${BUILD_NUMBER}" \
                                -d "projectKey=${SONAR_PROJECT_KEY}"
                            """,
                            returnStdout: true
                        )
                        
                        // Extraire le token de la réponse JSON
                        def tokenJson = readJSON text: scanToken
                        env.SONAR_SCAN_TOKEN = tokenJson.token
                        echo "Token d'analyse généré: ${env.SONAR_SCAN_TOKEN}"
                    }
                }
            }
        }

        stage('3️⃣ Build & Tests') {
            steps {
                echo '🔨 Compilation et tests...'
                sh 'mvn clean compile test'
                echo '✅ Build et tests terminés'
            }
        }

        stage('4️⃣ Analyse SonarQube') {
            steps {
                echo '🔍 Analyse de qualité du code...'
                script {
                    withCredentials([string(credentialsId: 'sonarqube-admin-token', variable: 'SONAR_ADMIN_TOKEN')]) {
                        // Utiliser le token généré ou le token admin
                        sh """
                            mvn sonar:sonar \
                            -Dsonar.host.url=${SONAR_HOST_URL} \
                            -Dsonar.login=${SONAR_ADMIN_TOKEN} \
                            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
                            -Dsonar.projectName="${SONAR_PROJECT_NAME}" \
                            -Dsonar.java.source=11 \
                            -Dsonar.sourceEncoding=UTF-8 \
                            -Dsonar.sources=src/main/java \
                            -Dsonar.tests=src/test/java \
                            -Dsonar.junit.reportsPath=target/surefire-reports \
                            -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
                        """
                    }
                }
                echo '✅ Analyse SonarQube terminée'
            }
        }

        stage('5️⃣ Vérifier Quality Gate') {
            steps {
                echo '🎯 Vérification du Quality Gate...'
                script {
                    withCredentials([string(credentialsId: 'sonarqube-admin-token', variable: 'SONAR_ADMIN_TOKEN')]) {
                        // Attendre que l'analyse soit terminée
                        sleep 30
                        
                        // Vérifier le statut du Quality Gate
                        def qualityGate = sh(
                            script: """
                                curl -s \
                                -u "${SONAR_ADMIN_TOKEN}:" \
                                "${SONAR_HOST_URL}/api/qualitygates/project_status?projectKey=${SONAR_PROJECT_KEY}"
                            """,
                            returnStdout: true
                        )
                        
                        def qgJson = readJSON text: qualityGate
                        def status = qgJson.projectStatus.status
                        
                        echo "Quality Gate Status: ${status}"
                        
                        if (status != "OK") {
                            error "❌ Quality Gate échoué! Voir: ${SONAR_HOST_URL}/dashboard?id=${SONAR_PROJECT_KEY}"
                        }
                    }
                }
                echo '✅ Quality Gate passé avec succès'
            }
        }

        stage('6️⃣ Package JAR') {
            steps {
                echo '📦 Création du JAR...'
                sh 'mvn package -DskipTests'
                echo '✅ JAR créé'
            }
        }

        stage('7️⃣ Build Image Docker') {
            steps {
                echo '🐳 Construction de l\'image Docker...'
                script {
                    // Créer le Dockerfile
                    sh '''
                        echo 'FROM openjdk:11-jre-slim' > Dockerfile
                        echo 'WORKDIR /app' >> Dockerfile
                        echo 'COPY target/*.jar app.jar' >> Dockerfile
                        echo 'EXPOSE 8080' >> Dockerfile
                        echo 'ENTRYPOINT ["java", "-jar", "app.jar"]' >> Dockerfile
                    '''
                    
                    // Build l'image
                    docker.build("linahadidi/student-app:${env.BUILD_ID}-${SONAR_PROJECT_KEY}")
                }
                echo '✅ Image Docker construite'
            }
        }

        stage('8️⃣ Déploiement Kubernetes') {
            steps {
                echo '🚀 Déploiement sur Kubernetes...'
                sh '''
                    # Créer le namespace si inexistant
                    kubectl create namespace devops --dry-run=client -o yaml | kubectl apply -f -
                    
                    # Déploiement avec l'image fraîchement buildée
                    cat > k8s-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${SONAR_PROJECT_KEY}-app
  labels:
    app: ${SONAR_PROJECT_KEY}
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ${SONAR_PROJECT_KEY}
  template:
    metadata:
      labels:
        app: ${SONAR_PROJECT_KEY}
      annotations:
        build.number: "${BUILD_NUMBER}"
        sonar.project: "${SONAR_PROJECT_KEY}"
    spec:
      containers:
      - name: ${SONAR_PROJECT_KEY}
        image: linahadidi/student-app:${BUILD_ID}-${SONAR_PROJECT_KEY}
        ports:
        - containerPort: 8080
        env:
        - name: SONAR_PROJECT_KEY
          value: "${SONAR_PROJECT_KEY}"
        - name: BUILD_NUMBER
          value: "${BUILD_NUMBER}"
---
apiVersion: v1
kind: Service
metadata:
  name: ${SONAR_PROJECT_KEY}-service
spec:
  selector:
    app: ${SONAR_PROJECT_KEY}
  ports:
  - port: 8080
    targetPort: 8080
    nodePort: 30080
  type: NodePort
EOF
                    
                    envsubst < k8s-deployment.yaml | kubectl apply -n devops -f -
                    rm k8s-deployment.yaml
                    
                    # Attendre le déploiement
                    sleep 30
                '''
                echo '✅ Déployé sur Kubernetes'
            }
        }

        stage('9️⃣ Vérification finale') {
            steps {
                echo '🔍 Vérification complète...'
                sh '''
                    echo "========================================"
                    echo "        RAPPORT FINAL"
                    echo "========================================"
                    echo ""
                    echo "📊 SONARQUBE:"
                    echo "   Projet: ${SONAR_PROJECT_NAME}"
                    echo "   Lien: ${SONAR_HOST_URL}/dashboard?id=${SONAR_PROJECT_KEY}"
                    echo "   Key: ${SONAR_PROJECT_KEY}"
                    echo ""
                    echo "🐳 DOCKER:"
                    echo "   Image: linahadidi/student-app:${BUILD_ID}-${SONAR_PROJECT_KEY}"
                    echo ""
                    echo "☸️ KUBERNETES:"
                    echo "   Namespace: devops"
                    kubectl get pods -n devops -l app=${SONAR_PROJECT_KEY}
                    echo ""
                    echo "   Service URL:"
                    minikube service ${SONAR_PROJECT_KEY}-service -n devops --url 2>/dev/null || echo "http://\$(minikube ip):30080"
                    echo ""
                    echo "✅ PIPELINE TERMINÉ AVEC SUCCÈS"
                    echo "========================================"
                '''
            }
        }

    }

    post {
        always {
            echo '🧹 Nettoyage...'
            sh '''
                rm -f Dockerfile 2>/dev/null || true
            '''
        }
        success {
            echo '🎉 🎉 🎉 FÉLICITATIONS ! 🎉 🎉 🎉'
            echo ''
            echo '📋 RÉSUMÉ:'
            echo '   1. Projet créé automatiquement dans SonarQube ✓'
            echo '   2. Analyse qualité du code ✓'
            echo '   3. Quality Gate vérifié ✓'
            echo '   4. Image Docker buildée ✓'
            echo '   5. Déploiement Kubernetes ✓'
            echo ''
            echo '🔗 LIENS:'
            echo "   - SonarQube: ${SONAR_HOST_URL}/dashboard?id=${SONAR_PROJECT_KEY}"
            echo "   - Application: http://$(minikube ip):30080"
            echo ''
        }
        failure {
            echo '❌ Pipeline échoué'
            sh '''
                echo "Derniers logs SonarQube:"
                tail -20 consoleText | grep -i sonar || true
                echo ""
                echo "État Kubernetes:"
                kubectl get pods -n devops 2>/dev/null || true
            '''
        }
    }
}
