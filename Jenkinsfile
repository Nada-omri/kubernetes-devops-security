pipeline {
  agent any
  environment{
    DOCKER_IMAGE = "devsecops"
    BUILD_TAG = "v.${BUILD_NUMBER}"
  }
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
      stage('Unit Tests-Junit and Jacoco') {
            steps {
              bat "mvn test"
              
            }
            post{
              always{
                junit 'target/surefire-reports/*.xml'
                jacoco execPattern: 'target/jacoco.exec'
              }
            }
        } 

    stage('Docker Build and Push') {
      steps {
        withDockerRegistry([credentialsId: "Dockerhub-credential", url: ""]) {
      bat 'docker build -t nadaomri/%DOCKER_IMAGE%:%BUILD_TAG% .'
      bat 'docker push nadaomri/%DOCKER_IMAGE%:%BUILD_TAG%'
        }
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