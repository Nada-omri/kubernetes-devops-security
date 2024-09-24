pipeline {
  agent any

  stages {
      stage('Checkout') {
            steps {
                // Clone the Git repository
                git credentialsId: 'github-credentials', url: 'https://github.com/Nada-omri/kubernetes-devops-security.git', branch: 'main'
            }
        }

      stage('Build Artifact-Maven') {
            steps {
              bat "mvn clean package -DskipTests=true"
              archive 'target/*.jar' //so that they can be downloaded later
            }
        } 
      stage('Unit Tests') {
            steps {
              bat "mvn test"
              
            }
        }  
        }
      post {
          success {
              echo 'Pipeline completed successfully!'
          }
          failure {
              echo 'Pipeline failed!'
          }
      }    
    }