pipeline {
  agent any
  environment {
    DOCKER_IMAGE = "devsecops"
    BUILD_TAG = "v.${BUILD_NUMBER}"
    KUBERNETES_FILE = 'C:\\ProgramData\\Jenkins\\.jenkins\\workspace\\Devsecops-training\\k8s_deployment_service.yaml'
    KUBERNETES_REPO_DIR = 'C:\\ProgramData\\Jenkins\\.jenkins\\workspace\\Devsecops-training'
  }
  stages {
    stage('Checkout') {
      steps {
        // Clone the Git repository via SSH
        git credentialsId: 'github-credentials', url: 'https://github.com/Nada-omri/kubernetes-devops-security.git', branch: 'main'
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

    stage('Update Kubernetes Image') {
      steps {
        script {
          // Replace the image in the Kubernetes YAML file
          bat "powershell -Command \"(Get-Content ${KUBERNETES_FILE}) -replace 'image: .*', 'image: nadaomri/${DOCKER_IMAGE}:${BUILD_TAG}' | Set-Content ${KUBERNETES_FILE}\""
        }
      }
    }

    stage('Kubernetes Deployment') {
      steps {
        script {
          // Change directory to the cloned repository
          dir(KUBERNETES_REPO_DIR) {
            // Configure Git
            bat 'git config user.email "nada.6.omri@gmail.com"'
            bat 'git config user.name "nada.6.omri@gmail.com"'

            // Add and commit changes
            bat "git add ${KUBERNETES_FILE}"
            bat 'git commit -m "Update Kubernetes image tag to ${BUILD_TAG}"'

            // Push changes
            bat 'git push origin main'
          }
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
