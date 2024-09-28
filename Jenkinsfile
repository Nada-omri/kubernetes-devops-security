pipeline {
  agent any
  environment {
    DOCKER_IMAGE = "devsecops"
    BUILD_TAG = "v.${BUILD_NUMBER}"
    KUBERNETES_FILE = 'C:\\ProgramData\\Jenkins\\.jenkins\\workspace\\devsecops\\projet-jenkins-test\\k8s_deployment_service.yaml'
    KUBERNETES_REPO_DIR = 'C:\\ProgramData\\Jenkins\\.jenkins\\workspace\\devsecops\\projet-jenkins-test'
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
            bat "docker build -t nadaomri/${DOCKER_IMAGE}:${BUILD_TAG} ."
            bat "docker push nadaomri/${DOCKER_IMAGE}:${BUILD_TAG}"
          }
        }
      }
    }

    stage('K8S Deployment - DEV') {
      steps {
        script {
          withKubeConfig([credentialsId: 'kubeconfig-credential']) {
            // Use PowerShell to replace the image tag in the Kubernetes YAML file
            bat """
            powershell -Command "(Get-Content ${KUBERNETES_FILE}) -replace 'replace', '${DOCKER_IMAGE}:${BUILD_TAG}' | Set-Content ${KUBERNETES_FILE}"
            """

            // Apply the Kubernetes deployment
            bat "kubectl -n default apply -f ${KUBERNETES_FILE}"
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
