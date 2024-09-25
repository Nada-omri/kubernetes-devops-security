pipeline {
  agent any
  environment {
    DOCKER_IMAGE = "devsecops"
    BUILD_TAG = "v.${BUILD_NUMBER}"
  }
  stages {
    stage('Checkout') {
      steps {
        // Clone the Git repository via SSH
        git credentialsId: 'github-ssh-credentials', url: 'git@github.com:Nada-omri/kubernetes-devops-security.git', branch: 'main'
      }
    }

    stage('Build Artifact-Maven') {
      steps {
        bat "mvn clean package -DskipTests=true"
        archiveArtifacts artifacts: 'target/*.jar', allowEmptyArchive: true
      }
    }

    stage('Unit Tests-Junit and Jacoco') {
      steps {
        bat "mvn test"
      }
      post {
        always {
          junit 'target/surefire-reports/*.xml'
          jacoco execPattern: 'target/jacoco.exec'
        }
      }
    }

    stage('Docker Build and Push') {
      steps {
        script {
          withDockerRegistry([credentialsId: "Dockerhub-credential", url: ""]) {
            bat "docker build -t nadaomri/%DOCKER_IMAGE%:%BUILD_TAG% ."
            bat "docker push nadaomri/%DOCKER_IMAGE%:%BUILD_TAG%"
          }
        }
      }
    }

    // New stage to update Kubernetes deployment
    stage('Kubernetes Deployment') {
      steps {
        script {
          def kubernetesFile = 'k8s_deployment_service.yaml' // Path to your Kubernetes file
          def imageTag = "nadaomri/${DOCKER_IMAGE}:${BUILD_TAG}"

          // Use PowerShell to replace the image tag in the Kubernetes YAML file
          powershell '''
            (Get-Content k8s_deployment_service.yaml) -replace 'image: .*', 'image: nadaomri/${DOCKER_IMAGE}:${BUILD_TAG}' | Set-Content k8s_deployment_service.yaml
          '''

          // Commit and push the changes to the Kubernetes YAML file
          bat '''
            git config --global user.email "nada.6.omri@gmail.com"
            git config --global user.name "nada.6.omri@gmail.com"
            git add k8s_deployment_service.yaml
            git commit -m "Update image to ${DOCKER_IMAGE}:${BUILD_TAG}"
            git push origin main -v --force --no-verify
          '''

          // Apply the updated Kubernetes deployment
          bat 'kubectl apply -f k8s_deployment_service.yaml'
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
