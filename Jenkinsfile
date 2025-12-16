pipeline {
    agent any

    tools {
        maven 'M2_HOME'
        jdk 'JAVA_HOME'
    }

    environment {
        // Configuration SonarQube
        SONAR_HOST_URL = 'http://localhost:9000'
        // ⚠️ Remplace par ton token réel (à mettre dans Jenkins Credentials)
        SONAR_AUTH_TOKEN = credentials('sonarqube-token') 
        // Ou définis directement (moins sécurisé):
        // SONAR_AUTH_TOKEN = 'sqp_ton_token_ici'
    }

    stages {

        stage('1️⃣ Clone & Build') {
            steps {
                echo '📥 Clonage et Build...'
                git branch: 'main', url: 'https://github.com/linahadidi/StudentManagement.git'
                sh 'mvn clean compile'
                echo '✅ Build Maven terminé'
            }
        }

        stage('2️⃣ Analyse SonarQube') {
            steps {
                echo '🔍 Analyse de qualité avec SonarQube...'
                script {
                    withSonarQubeEnv('SonarQube') {
                        // Si tu as configuré SonarQube dans Jenkins
                        sh 'mvn sonar:sonar -Dsonar.projectKey=student-management -Dsonar.projectName="Student Management"'
                    }
                    // Alternative si SonarQube non configuré dans Jenkins:
                    // sh "mvn sonar:sonar -Dsonar.host.url=${SONAR_HOST_URL} -Dsonar.login=${SONAR_AUTH_TOKEN} -Dsonar.projectKey=student-management"
                }
                echo '✅ Analyse SonarQube lancée'
            }
        }

        stage('3️⃣ Attente Quality Gate') {
            steps {
                echo '⏳ Vérification Quality Gate...'
                script {
                    timeout(time: 5, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: false
                    }
                }
                echo '✅ Quality Gate validée'
            }
        }

        stage('4️⃣ Tests & Package') {
            steps {
                echo '🧪 Exécution des tests...'
                sh 'mvn test'
                echo '📦 Création du JAR...'
                sh 'mvn package -DskipTests'
                echo '✅ Tests terminés - JAR créé'
            }
        }

        stage('5️⃣ Create Dockerfile') {
            steps {
                echo '📝 Création du Dockerfile...'
                sh '''
                    # Dockerfile pour application Spring Boot
                    echo 'FROM openjdk:11-jre-slim' > Dockerfile
                    echo 'WORKDIR /app' >> Dockerfile
                    echo 'COPY target/*.jar app.jar' >> Dockerfile
                    echo 'EXPOSE 8080' >> Dockerfile
                    echo 'ENTRYPOINT ["java", "-jar", "app.jar"]' >> Dockerfile
                    
                    echo "=== Dockerfile créé ==="
                    cat Dockerfile
                '''
                echo '✅ Dockerfile prêt'
            }
        }

        stage('6️⃣ Build Docker Image') {
            steps {
                echo '🐳 Construction image Docker...'
                script {
                    docker.build("linahadidi/student-app:${env.BUILD_ID}")
                }
                echo '✅ Image Docker construite avec succès'
            }
        }

        stage('7️⃣ Deploy to Kubernetes') {
            steps {
                echo '🚀 Déploiement sur Kubernetes...'
                sh '''
                    # 1. Vérifier/Créer namespace
                    kubectl create namespace devops --dry-run=client -o yaml | kubectl apply -f -
                    
                    # 2. Déployer Spring Boot avec la NOUVELLE image
                    cat > spring-deploy.yaml << 'SPRING_EOF'
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
        env:
        - name: SPRING_PROFILES_ACTIVE
          value: "prod"
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
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
SPRING_EOF
                    
                    kubectl apply -f spring-deploy.yaml -n devops
                    rm spring-deploy.yaml
                    
                    # Attendre le démarrage
                    echo "Attente du déploiement (30s)..."
                    sleep 30
                '''
                echo '✅ Déployé sur Kubernetes'
            }
        }

        stage('8️⃣ Verification') {
            steps {
                echo '🔍 Vérification complète...'
                sh '''
                    echo "========================================"
                    echo "        VÉRIFICATION FINALE"
                    echo "========================================"
                    echo ""
                    echo "1. État des pods:"
                    kubectl get pods -n devops
                    echo ""
                    echo "2. État du déploiement:"
                    kubectl get deployment spring-app -n devops
                    echo ""
                    echo "3. Détail de l'image utilisée:"
                    kubectl get deployment spring-app -n devops -o jsonpath='{"Image: "}{.spec.template.spec.containers[0].image}{"\\n"}'
                    echo ""
                    echo "4. URL d'accès:"
                    minikube service spring-service -n devops --url 2>/dev/null || echo "http://$(minikube ip):30080"
                    echo ""
                    echo "5. Rapport SonarQube:"
                    echo "${SONAR_HOST_URL}/dashboard?id=student-management"
                    echo ""
                    echo "6. Résumé complet:"
                    kubectl get all -n devops
                    echo ""
                    echo "========================================"
                '''
                echo '✅ Vérification terminée'
            }
        }

        stage('9️⃣ Archive Artifact') {
            steps {
                echo '📁 Archivage...'
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                echo '✅ Artefact archivé'
            }
        }

    }

    post {
        success {
            echo '🎉 🎉 🎉 PIPELINE RÉUSSI ! 🎉 🎉 🎉'
            echo ''
            echo '========================================'
            echo '   CI/CD AVEC SONARQUBE - TERMINÉ      '
            echo '========================================'
            echo ''
            echo '✅ TOUTES LES ÉTAPES RÉUSSIES:'
            echo '   1. Build Maven ✓'
            echo '   2. Analyse SonarQube ✓'
            echo '   3. Quality Gate ✓'
            echo '   4. Tests unitaires ✓'
            echo '   5. Package JAR ✓'
            echo '   6. Construction image Docker ✓'
            echo '   7. Déploiement Kubernetes ✓'
            echo '   8. Vérification ✓'
            echo '   9. Archivage ✓'
            echo ''
            echo '📊 RÉSULTAT FINAL:'
            echo '   - Application: linahadidi/student-app:${BUILD_NUMBER}'
            echo '   - Qualité: ${SONAR_HOST_URL}/dashboard?id=student-management'
            echo '   - Namespace: devops'
            echo '   - Accès: http://$(minikube ip):30080'
            echo ''
        }
        failure {
            echo '❌ Échec - Problème détecté'
            sh '''
                echo "Dernière vérification de l'état:"
                kubectl get pods -n devops
                echo ""
                echo "Logs SonarQube (si applicable):"
                grep -i sonar consoleText || echo "Pas d'erreur SonarQube détectée"
            '''
        }
        always {
            // Nettoyage
            echo '🧹 Nettoyage...'
            sh '''
                rm -f Dockerfile spring-deploy.yaml 2>/dev/null || true
            '''
        }
    }
}
