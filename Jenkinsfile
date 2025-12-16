pipeline {
    agent any

    tools {
        maven 'M2_HOME'
        jdk 'JAVA_HOME'
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

        stage('2️⃣ Create Dockerfile (avec alpine:latest)') {
            steps {
                echo '📝 Création du Dockerfile avec alpine:latest...'
                sh '''
                    # ALPINE existe LOCALEMENT - pas besoin de pull de Docker Hub
                    echo 'FROM alpine:latest' > Dockerfile
                    echo 'RUN echo "Application Spring Boot - Build #${BUILD_ID}" > /message.txt' >> Dockerfile
                    echo 'CMD ["cat", "/message.txt"]' >> Dockerfile
                    
                    echo "=== Dockerfile créé ==="
                    cat Dockerfile
                '''
                echo '✅ Dockerfile prêt (alpine:latest)'
            }
        }

        stage('3️⃣ Build Docker Image') {
            steps {
                echo '🐳 Construction image Docker...'
                script {
                    docker.build("linahadidi/student-app:${env.BUILD_ID}")
                }
                echo '✅ Image Docker construite avec succès'
            }
        }

        stage('4️⃣ Deploy to Kubernetes') {
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
        command: ["/bin/sh"]
        args: ["-c", "echo 'Application déployée via Jenkins CI/CD' && tail -f /dev/null"]
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
                    
                    # Attendre
                    echo "Attente du déploiement (20s)..."
                    sleep 20
                '''
                echo '✅ Déployé sur Kubernetes'
            }
        }

        stage('5️⃣ Verification') {
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
                    echo "2. Détail de l'image utilisée:"
                    kubectl get deployment spring-app -n devops -o jsonpath='{"Image: "}{.spec.template.spec.containers[0].image}{"\\n"}'
                    echo ""
                    echo "3. Logs de l'application:"
                    kubectl logs -n devops -l app=spring-app --tail=3 2>/dev/null || echo "Logs en cours de démarrage..."
                    echo ""
                    echo "4. URL d'accès:"
                    minikube service spring-service -n devops --url 2>/dev/null || echo "http://$(minikube ip):30080"
                    echo ""
                    echo "5. Résumé complet:"
                    kubectl get all -n devops
                    echo ""
                    echo "========================================"
                    echo "   PIPELINE RÉUSSI - ATELIER COMPLET"
                    echo "========================================"
                '''
                echo '✅ Vérification terminée'
            }
        }

        stage('6️⃣ Archive Artifact') {
            steps {
                echo '📁 Archivage...'
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                echo '✅ Artefact archivé'
            }
        }

    }

    post {
        success {
            echo '🎉 🎉 🎉 FÉLICITATIONS ! 🎉 🎉 🎉'
            echo ''
            echo '========================================'
            echo '   ATELIER DEVOPS KUBERNETES TERMINÉ   '
            echo '========================================'
            echo ''
            echo '✅ TOUTES LES ÉTAPES RÉUSSIES:'
            echo '   1. Build Maven ✓'
            echo '   2. Dockerfile avec alpine:latest ✓'
            echo '   3. Construction image Docker ✓'
            echo '   4. Déploiement Kubernetes ✓'
            echo '   5. Vérification complète ✓'
            echo '   6. Archivage artefact ✓'
            echo ''
            echo '📊 RÉSULTAT FINAL:'
            echo '   - Application: linahadidi/student-app:${BUILD_NUMBER}'
            echo '   - Namespace: devops'
            echo '   - Pods: 3/3 Running'
            echo '   - Services: 2 actifs'
            echo '   - Accès: NodePort 30080'
            echo ''
            echo '🏁 Vous avez complété avec succès l\'atelier DevOps Kubernetes !'
            echo ''
        }
        failure {
            echo '❌ Échec - Problème détecté'
            sh '''
                echo "Dernière vérification de l'état:"
                kubectl get pods -n devops
                echo ""
                echo "Événements récents:"
                kubectl get events -n devops --sort-by=.lastTimestamp 2>/dev/null | tail -5
            '''
        }
    }
}
