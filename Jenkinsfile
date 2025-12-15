pipeline {
    agent any

    tools {
        maven 'M2_HOME'     // correspond à ton installation Maven sur Jenkins
        jdk 'JAVA_HOME'     // correspond à ton installation JDK sur Jenkins
    }

    stages {

        stage('1️⃣ Clone Repository') {
            steps {
                echo '📥 Clonage du repository Git...'
                git branch: 'main', url: 'https://github.com/linahadidi/StudentManagement.git'
                echo '✅ Clonage terminé'
            }
        }

        stage('2️⃣ Build Project') {
            steps {
                echo '🔨 Compilation du projet avec Maven...'
                sh 'mvn clean compile -DskipTests'
                echo '✅ Build terminé'
            }
        }

        stage('3️⃣ Test & Package (Tests Sautés)') {
            steps {
                echo '📦 Packaging du projet (tests sautés)...'
                sh 'mvn package -DskipTests'
                echo '✅ Packaging terminé'
            }
        }

        stage('4️⃣ Package JAR') {
            steps {
                echo '📦 Packaging final en JAR...'
                sh 'mvn clean package -DskipTests'
                echo '✅ JAR prêt'
            }
        }

        stage('5️⃣ Build Docker Image') {
            steps {
                echo '🐳 Construction de l\'image Docker...'
                script {
                    docker.build("linahadidi/student-app:${env.BUILD_ID}")
                }
                echo '✅ Image Docker construite'
            }
        }

        stage('6️⃣ Push Docker Image') {
            steps {
                echo '📤 Pushing de l\'image vers Docker Hub...'
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-credentials') {
                        docker.image("linahadidi/student-app:${env.BUILD_ID}").push()
                        docker.image("linahadidi/student-app:${env.BUILD_ID}").push('latest')
                    }
                }
                echo '✅ Image poussée vers Docker Hub'
            }
        }

        stage('7️⃣ Deploy to Kubernetes') {
            steps {
                echo '🚀 Déploiement sur Kubernetes...'
                sh '''
                    # Appliquer les configurations Kubernetes
                    kubectl apply -f k8s/mysql-deployment.yaml -n devops
                    kubectl apply -f k8s/spring-deployment.yaml -n devops
                    
                    # Attendre que les pods soient prêts
                    sleep 30
                    kubectl get pods -n devops
                '''
                echo '✅ Déploiement Kubernetes terminé'
            }
        }

        stage('8️⃣ Verification') {
            steps {
                echo '🔍 Vérification du déploiement...'
                sh '''
                    kubectl get pods -n devops
                    kubectl get svc -n devops
                    echo "Application disponible sur:"
                    minikube service spring-service -n devops --url || true
                '''
                echo '✅ Vérification terminée'
            }
        }

        stage('9️⃣ Archive Artifact') {
            steps {
                echo '📁 Archivage du fichier JAR...'
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                echo '✅ Artifact archivé'
            }
        }

    } // fermeture du bloc stages

    post {
        failure {
            echo '❌ Le pipeline a échoué'
        }
        success {
            echo '🎉 Pipeline terminé avec succès'
            echo '🌐 Application déployée sur Kubernetes'
            echo '📊 Vérifiez avec: kubectl get all -n devops'
        }
    } // fermeture du bloc post
} // fermeture du bloc pipeline
