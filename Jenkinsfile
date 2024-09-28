pipeline {
  agent any
  environment {
    DOCKER_IMAGE = "devsecops"
    BUILD_TAG = "v.${BUILD_NUMBER}"
    KUBERNETES_FILE = 'C:\\ProgramData\\Jenkins\\.jenkins\\workspace\\Devsecops-training\\k8s_deployment_service.yaml'
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

    // Groovy stage for updating Kubernetes YAML
    stage('Update Kubernetes File with Groovy') {
      steps {
        script {
          // Lire le contenu du fichier Kubernetes YAML
          def kubernetesFile = readFile("${KUBERNETES_FILE}")
          // Remplacer l'image dans le fichier
          def updatedKubernetesFile = kubernetesFile.replaceAll('replace', "${DOCKER_IMAGE}:${BUILD_TAG}")
          // Réécrire le fichier avec le contenu mis à jour
          writeFile file: "${KUBERNETES_FILE}", text: updatedKubernetesFile
        }
      }
    }

    stage('K8S Deployment - DEV') {
      steps {
        script {
          withKubeConfig([credentialsId: 'kubeconfig-credential']) {
            // Appliquer le déploiement Kubernetes mis à jour
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
