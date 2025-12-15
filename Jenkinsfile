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

    } // fermeture du bloc stages

    post {
        failure {
            echo '❌ Le pipeline a échoué'
        }
        success {
            echo '🎉 Pipeline terminé avec succès'
        }
    } // fermeture du bloc post
} // fermeture du bloc pipeline
