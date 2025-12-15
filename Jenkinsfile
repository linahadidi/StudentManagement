pipeline {
    agent any

    tools {
        maven 'M2_HOME'     // Maven configuré dans Jenkins
        jdk 'JAVA_HOME'     // JDK configuré dans Jenkins
    }

    stages {

        stage('1️⃣ Clone Repository') {
            steps {
                echo '📥 Clonage du repository Git...'
                git branch: 'main',
                    url: 'https://github.com/linahadidi/StudentManagement.git'
                echo '✅ Clonage terminé'
            }
        }

        stage('2️⃣ Build & Compile') {
            steps {
                echo '🔨 Build et compilation avec Maven...'
                sh 'mvn clean compile'
                echo '✅ Build terminé'
            }
        }

        stage('3️⃣ Test & Package JAR') {
            steps {
                echo '🧪 Exécution des tests + Packaging JAR...'
                sh 'mvn test'
                sh 'mvn package'
                echo '📦 JAR généré avec succès'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
            }
        }
    }

    post {
        failure {
            echo '❌ Le pipeline a échoué'
        }
        success {
            echo '🎉 Pipeline terminé avec succès'
        }
    }
}
