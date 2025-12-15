
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
        
    }

        stage('5️⃣ Archive Artifact') {
            steps {
                echo '📁 Archivage du fichier JAR...'
                archiveArtifacts artifactspost {
        failure {
            echo '❌ Le pipeline a échoué'
        }
        success {
            echo '🎉 Pipeline terminé avec succès'
        }
    }
}
github.com
