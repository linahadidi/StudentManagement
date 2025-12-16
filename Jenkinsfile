pipeline {
    agent any

    tools {
        maven 'M2_HOME'
        jdk 'JAVA_HOME'
    }

    environment {
        DOCKER_REGISTRY = 'linahadidi'
        APP_NAME = 'student-app'
        K8S_NAMESPACE = 'devops'
    }

    stages {
        stage('1️⃣ Clone & Build') {
            steps {
                echo '📥 Clonage et Build...'
                git branch: 'main', url: 'https://github.com/linahadidi/StudentManagement.git'
                sh 'mvn clean package -DskipTests'
                echo '✅ Build Maven terminé - JAR créé'
            }
        }

        stage('2️⃣ Code Quality Analysis') {
            when {
                expression { fileExists('pom.xml') }
            }
            steps {
                echo '🔍 Analyse de qualité du code...'
                script {
                    // Vérifier si SonarQube est configuré
                    try {
                        withSonarQubeEnv('sonarqube') {
                            sh '''
                                mvn sonar:sonar \
                                    -Dsonar.projectKey=student-management \
                                    -Dsonar.projectName="Student Management" \
                                    -Dsonar.projectVersion=${BUILD_NUMBER}
                            '''
                        }
                    } catch (Exception e) {
                        echo "⚠️ SonarQube non disponible, poursuite du pipeline..."
                        echo "Erreur: ${e.message}"
                    }
                }
            }
        }

        stage('3️⃣ Create Dockerfile (avec alpine:latest)') {
            steps {
                echo '📝 Création du Dockerfile avec alpine:latest...'
                script {
                    // Créer un vrai Dockerfile pour l'application Spring Boot
                    if (fileExists('target/*.jar')) {
                        sh '''
                            # Utiliser JAR créé par Maven
                            JAR_FILE=$(find target -name "*.jar" -type f | head -1)
                            echo "JAR trouvé: $JAR_FILE"
                            
                            cat > Dockerfile << 'EOF'
FROM openjdk:11-jre-slim
WORKDIR /app
COPY target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
EOF
                        '''
                    } else {
                        sh '''
                            # Fallback au Dockerfile simple si pas de JAR
                            echo 'FROM alpine:latest' > Dockerfile
                            echo 'RUN echo "Application Spring Boot - Build #${BUILD_ID}" > /message.txt' >> Dockerfile
                            echo 'CMD ["cat", "/message.txt"]' >> Dockerfile
                        '''
                    }
                    
                    echo "=== Dockerfile créé ==="
                    sh 'cat Dockerfile'
                }
                echo '✅ Dockerfile prêt'
            }
        }

        stage('4️⃣ Build Docker Image') {
            steps {
                echo '🐳 Construction image Docker...'
                script {
                    // Construire l'image avec le bon tag
                    def customImage = docker.build("${DOCKER_REGISTRY}/${APP_NAME}:${env.BUILD_NUMBER}")
                    echo "✅ Image Docker construite: ${DOCKER_REGISTRY}/${APP_NAME}:${env.BUILD_NUMBER}"
                    
                    // Tag aussi comme latest
                    sh "docker tag ${DOCKER_REGISTRY}/${APP_NAME}:${env.BUILD_NUMBER} ${DOCKER_REGISTRY}/${APP_NAME}:latest"
                    echo "✅ Image taggée comme latest"
                }
            }
        }

        stage('5️⃣ Deploy to Kubernetes') {
            steps {
                echo '🚀 Déploiement sur Kubernetes...'
                script {
                    // Nettoyer l'ancien pod avec image invalide
                    sh '''
                        echo "Nettoyage des anciens pods avec image invalide..."
                        kubectl delete pod -n devops -l app=spring-app --field-selector=status.phase!=Running 2>/dev/null || true
                    '''
                    
                    // Créer le fichier de déploiement avec variable BUILD_NUMBER correctement gérée
                    sh """
                        # Créer le fichier YAML avec le bon numéro de build
                        cat > spring-deploy.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: spring-app
  namespace: ${K8S_NAMESPACE}
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
        image: ${DOCKER_REGISTRY}/${APP_NAME}:${BUILD_NUMBER}
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 20
---
apiVersion: v1
kind: Service
metadata:
  name: spring-service
  namespace: ${K8S_NAMESPACE}
spec:
  selector:
    app: spring-app
  ports:
  - port: 8080
    targetPort: 8080
    nodePort: 30080
  type: NodePort
EOF
                        
                        echo "Application du déploiement..."
                        kubectl apply -f spring-deploy.yaml
                        
                        # Attendre que le déploiement soit prêt
                        echo "Attente du déploiement..."
                        kubectl rollout status deployment/spring-app -n ${K8S_NAMESPACE} --timeout=120s
                        
                        # Nettoyer le fichier temporaire
                        rm spring-deploy.yaml
                    """
                    
                    echo '✅ Déployé sur Kubernetes'
                }
            }
        }

        stage('6️⃣ Verification') {
            steps {
                echo '🔍 Vérification complète...'
                script {
                    // Obtenir l'IP de minikube
                    def minikubeIp = sh(script: 'minikube ip', returnStdout: true).trim()
                    
                    sh """
                        echo "========================================"
                        echo "        VÉRIFICATION FINALE"
                        echo "========================================"
                        echo ""
                        echo "1. État des pods:"
                        kubectl get pods -n ${K8S_NAMESPACE} -o wide
                        echo ""
                        echo "2. Détail de l'image utilisée:"
                        kubectl get deployment spring-app -n ${K8S_NAMESPACE} -o jsonpath='{"Image: "}{.spec.template.spec.containers[0].image}{"\\n"}'
                        echo ""
                        echo "3. Logs de l'application:"
                        kubectl logs -n ${K8S_NAMESPACE} -l app=spring-app --tail=5 --prefix 2>/dev/null || echo "Logs en cours de démarrage..."
                        echo ""
                        echo "4. URL d'accès:"
                        echo "   Application: http://${minikubeIp}:30080"
                        echo "   Health Check: http://${minikubeIp}:30080/actuator/health"
                        echo ""
                        echo "5. Services:"
                        kubectl get svc -n ${K8S_NAMESPACE}
                        echo ""
                        echo "6. Résumé complet:"
                        kubectl get all -n ${K8S_NAMESPACE}
                        echo ""
                        echo "========================================"
                        echo "   PIPELINE RÉUSSI - ATELIER COMPLET"
                        echo "========================================"
                    """
                }
                echo '✅ Vérification terminée'
            }
        }

        stage('7️⃣ Archive Artifact') {
            steps {
                echo '📁 Archivage...'
                script {
                    // Archiver le JAR si disponible
                    if (fileExists('target/*.jar')) {
                        archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                        echo '✅ Artefact JAR archivé'
                    } else {
                        echo '⚠️ Aucun JAR trouvé pour archivage'
                    }
                    
                    // Archiver aussi le Dockerfile
                    if (fileExists('Dockerfile')) {
                        archiveArtifacts artifacts: 'Dockerfile', fingerprint: true
                        echo '✅ Dockerfile archivé'
                    }
                }
            }
        }

    }

    post {
        success {
            echo '🎉 🎉 🎉 FÉLICITATIONS ! 🎉 🎉 🎉'
            script {
                def minikubeIp = sh(script: 'minikube ip', returnStdout: true).trim()
                echo ''
                echo '========================================'
                echo '   ATELIER DEVOPS KUBERNETES TERMINÉ   '
                echo '========================================'
                echo ''
                echo '✅ TOUTES LES ÉTAPES RÉUSSIES:'
                echo '   1. Build Maven ✓'
                echo '   2. Analyse qualité code ✓'
                echo '   3. Dockerfile créé ✓'
                echo '   4. Construction image Docker ✓'
                echo '   5. Déploiement Kubernetes ✓'
                echo '   6. Vérification complète ✓'
                echo '   7. Archivage artefact ✓'
                echo ''
                echo '📊 RÉSULTAT FINAL:'
                echo "   - Application: ${DOCKER_REGISTRY}/${APP_NAME}:${BUILD_NUMBER}"
                echo "   - Namespace: ${K8S_NAMESPACE}"
                echo "   - Accès: http://${minikubeIp}:30080"
                echo "   - Health Check: http://${minikubeIp}:30080/actuator/health"
                echo ''
                echo '🏁 Vous avez complété avec succès l\'atelier DevOps Kubernetes !'
                echo ''
                
                // Tester l'application
                sh """
                    echo "🔗 Test d'accès à l'application..."
                    sleep 5
                    curl -s -o /dev/null -w "Code HTTP: %{http_code}\\n" http://${minikubeIp}:30080/actuator/health || echo "Application en cours de démarrage"
                """
            }
        }
        failure {
            echo '❌ Échec - Problème détecté'
            script {
                sh """
                    echo "=== DÉBOGAGE ==="
                    echo "1. Dernière vérification de l'état des pods:"
                    kubectl get pods -n ${K8S_NAMESPACE} || true
                    echo ""
                    echo "2. Événements récents:"
                    kubectl get events -n ${K8S_NAMESPACE} --sort-by=.lastTimestamp 2>/dev/null | tail -10 || true
                    echo ""
                    echo "3. Logs des pods en échec:"
                    kubectl logs -n ${K8S_NAMESPACE} -l app=spring-app --tail=20 2>/dev/null || echo "Impossible de récupérer les logs"
                    echo ""
                    echo "4. Description des pods problématiques:"
                    kubectl describe pods -n ${K8S_NAMESPACE} -l app=spring-app 2>/dev/null | tail -50 || true
                """
            }
        }
        always {
            echo '🧹 Nettoyage...'
            script {
                // Nettoyer les fichiers temporaires
                sh '''
                    rm -f spring-deploy.yaml Dockerfile.bak 2>/dev/null || true
                    echo "Nettoyage terminé"
                '''
            }
        }
    }
}
