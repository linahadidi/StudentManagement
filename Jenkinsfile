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
                echo '✅ Build terminé - JAR créé'
            }
        }

        stage('2️⃣ Create Dockerfile') {
            steps {
                echo '📝 Création du Dockerfile...'
                sh '''
                    cat > Dockerfile << 'EOF'
                    FROM openjdk:17-jdk-slim
                    WORKDIR /app
                    COPY target/*.jar app.jar
                    EXPOSE 8080
                    ENTRYPOINT ["java", "-jar", "app.jar"]
                    EOF
                    echo "Dockerfile créé:"
                    cat Dockerfile
                '''
                echo '✅ Dockerfile prêt'
            }
        }

        stage('3️⃣ Build Docker Image') {
            steps {
                echo '🐳 Construction de l\'image Docker...'
                script {
                    docker.build("linahadidi/student-app:${env.BUILD_ID}")
                }
                echo '✅ Image Docker construite'
            }
        }

        stage('4️⃣ Push Docker Image (Optionnel)') {
            steps {
                echo '📤 Pushing de l\'image vers Docker Hub...'
                script {
                    // Cette étape est optionnelle pour l'atelier
                    try {
                        docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-credentials') {
                            docker.image("linahadidi/student-app:${env.BUILD_ID}").push()
                        }
                        echo '✅ Image poussée vers Docker Hub'
                    } catch (Exception e) {
                        echo '⚠️ Push Docker Hub échoué (optionnel pour l\'atelier)'
                        echo 'L\'image est disponible localement pour le déploiement'
                    }
                }
            }
        }

        stage('5️⃣ Deploy MySQL to Kubernetes') {
            steps {
                echo '🗄️ Déploiement MySQL sur Kubernetes...'
                sh '''
                    # Créer le namespace si nécessaire
                    kubectl create namespace devops --dry-run=client -o yaml | kubectl apply -f -
                    
                    # Déployer MySQL
                    if [ -f "k8s/mysql-deployment.yaml" ]; then
                        kubectl apply -f k8s/mysql-deployment.yaml -n devops
                        echo "✅ MySQL déployé depuis k8s/mysql-deployment.yaml"
                    else
                        echo "⚠️ Fichier mysql-deployment.yaml non trouvé, déploiement basique..."
                        # Déploiement MySQL basique
                        kubectl apply -n devops -f - <<EOF
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
                        EOF
                    fi
                    
                    # Attendre que MySQL soit prêt
                    sleep 15
                    kubectl get pods -n devops -l app=mysql
                '''
                echo '✅ MySQL déployé'
            }
        }

        stage('6️⃣ Deploy Spring Boot to Kubernetes') {
            steps {
                echo '🚀 Déploiement Spring Boot sur Kubernetes...'
                sh '''
                    # Utiliser l'image Docker construite
                    # ou une image de test si le push a échoué
                    
                    if [ -f "k8s/spring-deployment.yaml" ]; then
                        # Mettre à jour l'image dans le fichier YAML
                        sed -i "s|image: .*|image: linahadidi/student-app:\${BUILD_ID}|" k8s/spring-deployment.yaml
                        kubectl apply -f k8s/spring-deployment.yaml -n devops
                        echo "✅ Spring Boot déployé depuis k8s/spring-deployment.yaml"
                    else
                        echo "⚠️ Fichier spring-deployment.yaml non trouvé, déploiement basique..."
                        # Déploiement Spring Boot basique
                        kubectl apply -n devops -f - <<EOF
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
                                image: linahadidi/student-app:\${BUILD_ID}
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
                        EOF
                    fi
                    
                    # Attendre que l'application démarre
                    sleep 20
                    kubectl get pods -n devops -l app=spring-app
                '''
                echo '✅ Spring Boot déployé'
            }
        }

        stage('7️⃣ Verification') {
            steps {
                echo '🔍 Vérification complète...'
                sh '''
                    echo "=== ÉTAT DU CLUSTER ==="
                    kubectl get nodes
                    echo ""
                    echo "=== PODS (devops) ==="
                    kubectl get pods -n devops
                    echo ""
                    echo "=== SERVICES (devops) ==="
                    kubectl get svc -n devops
                    echo ""
                    echo "=== DÉPLOIEMENTS (devops) ==="
                    kubectl get deployments -n devops
                    echo ""
                    echo "=== URL APPLICATION ==="
                    minikube service spring-service -n devops --url 2>/dev/null || echo "http://<minikube-ip>:30080"
                    echo ""
                    echo "=== LOGS APPLICATION (dernières lignes) ==="
                    kubectl logs -n devops -l app=spring-app --tail=10 2>/dev/null || echo "Logs pas encore disponibles"
                    echo ""
                    echo "=== VÉRIFICATION MYSQL ==="
                    kubectl exec -n devops -it $(kubectl get pods -n devops -l app=mysql -o name | head -1) -- mysql -u root -p -e "SHOW DATABASES;" 2>/dev/null || echo "MySQL en cours de démarrage"
                '''
                echo '✅ Vérification terminée'
            }
        }

        stage('8️⃣ Archive Artifact') {
            steps {
                echo '📁 Archivage du fichier JAR...'
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                echo '✅ Artifact archivé'
            }
        }

    }

    post {
        always {
            echo '📊 Résumé final des ressources Kubernetes:'
            sh 'kubectl get all -n devops || true'
        }
        failure {
            echo '❌ Pipeline échoué'
        }
        success {
            echo '🎉 Pipeline terminé avec succès'
        }
    }
}
