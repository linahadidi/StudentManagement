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

        stage('2️⃣ Create Dockerfile') {
            steps {
                echo '📝 Création du Dockerfile...'
                sh '''
                    # Créer un Dockerfile CORRECT sans EOF problématique
                    echo 'FROM openjdk:17-slim' > Dockerfile
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

        stage('3️⃣ Build Docker Image') {
            steps {
                echo '🐳 Construction image Docker...'
                script {
                    docker.build("linahadidi/student-app:${env.BUILD_ID}")
                }
                echo '✅ Image Docker construite'
            }
        }

        stage('4️⃣ Deploy to Kubernetes') {
            steps {
                echo '🚀 Déploiement sur Kubernetes...'
                sh '''
                    # Vérifier/Créer namespace
                    kubectl create namespace devops --dry-run=client -o yaml | kubectl apply -f -
                    
                    # 1. Vérifier et déployer MySQL si nécessaire
                    if ! kubectl get deployment mysql -n devops >/dev/null 2>&1; then
                        echo "Déploiement de MySQL..."
                        cat > mysql-deploy.yaml << 'MYSQL_EOF'
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/data/mysql"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: root123
        - name: MYSQL_DATABASE
          value: springdb
        ports:
        - containerPort: 3306
        volumeMounts:
        - mountPath: /var/lib/mysql
          name: mysql-storage
      volumes:
      - name: mysql-storage
        persistentVolumeClaim:
          claimName: mysql-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
spec:
  selector:
    app: mysql
  ports:
  - port: 3306
    targetPort: 3306
  type: ClusterIP
MYSQL_EOF
                        kubectl apply -f mysql-deploy.yaml -n devops
                        rm mysql-deploy.yaml
                    else
                        echo "MySQL déjà déployé"
                    fi
                    
                    # 2. Déployer/redéployer Spring Boot avec la nouvelle image
                    echo "Déploiement de Spring Boot..."
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
        - name: SPRING_DATASOURCE_URL
          value: jdbc:mysql://mysql-service:3306/springdb
        - name: SPRING_DATASOURCE_USERNAME
          value: spring
        - name: SPRING_DATASOURCE_PASSWORD
          value: spring123
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
                    
                    # Attendre le déploiement
                    echo "Attente du déploiement..."
                    sleep 30
                '''
                echo '✅ Déployé sur Kubernetes'
            }
        }

        stage('5️⃣ Verification') {
            steps {
                echo '🔍 Vérification complète...'
                sh '''
                    echo "========================================"
                    echo "        VÉRIFICATION KUBERNETES         "
                    echo "========================================"
                    echo ""
                    echo "1. État du cluster:"
                    kubectl get nodes
                    echo ""
                    echo "2. Tous les pods (namespace devops):"
                    kubectl get pods -n devops
                    echo ""
                    echo "3. Tous les services (namespace devops):"
                    kubectl get svc -n devops
                    echo ""
                    echo "4. Détail du déploiement Spring Boot:"
                    kubectl describe deployment spring-app -n devops | grep -A 5 "Image"
                    echo ""
                    echo "5. URL d'accès à l'application:"
                    minikube service spring-service -n devops --url 2>/dev/null || echo "http://$(minikube ip):30080"
                    echo ""
                    echo "6. Logs de l'application (premier pod):"
                    kubectl logs -n devops -l app=spring-app --tail=5 2>/dev/null || echo "Logs pas encore disponibles - le pod démarre..."
                    echo ""
                    echo "========================================"
                '''
                echo '✅ Vérification terminée'
            }
        }

        stage('6️⃣ Archive Artifact') {
            steps {
                echo '📁 Archivage de l\'artefact...'
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                echo '✅ Artefact archivé'
            }
        }

    }

    post {
        always {
            echo '📊 Résumé final:'
            sh '''
                echo "=== RÉSUMÉ KUBERNETES ==="
                kubectl get all -n devops
                echo ""
                echo "=== IMAGE DÉPLOYÉE ==="
                kubectl get deployment spring-app -n devops -o jsonpath='{.spec.template.spec.containers[0].image}'
                echo ""
            '''
        }
        success {
            echo '🎉 🎉 🎉 PIPELINE RÉUSSI ! 🎉 🎉 🎉'
            echo ''
            echo '========================================'
            echo '   ATELIER DEVOPS KUBERNETES COMPLET   '
            echo '========================================'
            echo ''
            echo '✅ TOUTES LES ÉTAPES RÉUSSIES :'
            echo '   1. ✅ Build Maven'
            echo '   2. ✅ Création Dockerfile'
            echo '   3. ✅ Construction image Docker'
            echo '   4. ✅ Déploiement Kubernetes'
            echo '   5. ✅ Vérification'
            echo '   6. ✅ Archivage artefact'
            echo ''
            echo '🔧 RESSOURCES DÉPLOYÉES :'
            echo '   - MySQL avec PersistentVolume'
            echo '   - Application Spring Boot (2 replicas)'
            echo '   - Services: MySQL (ClusterIP), App (NodePort:30080)'
            echo ''
            echo '🏁 FÉLICITATIONS ! Pipeline CI/CD Kubernetes terminé avec succès !'
            echo ''
        }
        failure {
            echo '❌ Pipeline échoué - vérifiez les logs ci-dessus'
            sh '''
                echo "=== DERNIERS ÉVÉNEMENTS ==="
                kubectl get events -n devops --sort-by=.lastTimestamp | tail -10
                echo ""
                echo "=== DESCRIPTION DU PROBLÈME ==="
                kubectl describe pods -n devops -l app=spring-app 2>/dev/null | grep -A 10 "Events"
            '''
        }
    }
}
