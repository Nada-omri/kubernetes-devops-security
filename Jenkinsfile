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
              sh "mvn clean package -DskipTests=true"
              archive 'target/*.jar' //so that they can be downloaded later
            }
        } 
      stage('Unit Tests') {
            steps {
              sh "mvn test"
              
            }
        }  
        }    
    }
