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
            bat "docker build -t nadaomri/%DOCKER_IMAGE%:%BUILD_TAG% ."
            bat "docker push nadaomri/%DOCKER_IMAGE%:%BUILD_TAG%"
          }
        }
      }
    }

    stage('Checkout Kubernetes Repo') {
                steps {
                    script {
                        def repoUrl = 'https://github.com/Nada-omri/kubernetes-devops-security.git'
                        bat "git clone ${repoUrl} ${KUBERNETES_REPO_DIR}"
                    }
                }
            }

    stage('Update Kubernetes File') {
      steps {
        script {
          // Ensure the Kubernetes file exists after cloning
          if (fileExists(KUBERNETES_FILE)) {
            // Read the Kubernetes file
            def kubernetesFile = readFile(KUBERNETES_FILE)
            // Replace the image tag in the Kubernetes file
            def updatedKubernetesFile = kubernetesFile.replaceAll(/image: nadaomri\/devsecops:.+/, "image: nadaomri/devsecops:${BUILD_TAG}")
            // Write the updated content back to the Kubernetes file
            writeFile file: KUBERNETES_FILE, text: updatedKubernetesFile
            // Print the updated content for verification
            echo "Updated Kubernetes file content:\n${updatedKubernetesFile}"
          } else {
            error "Kubernetes file not found: ${KUBERNETES_FILE}"
          }
        }
      }
    }

    stage('Clone, Commit, Push and Clean Up') {
      steps {
        script {
          // Change directory to the cloned repository
          dir(KUBERNETES_REPO_DIR) {
            // Configure Git
            bat 'git config user.name "nada.6.omri@gmail.com"'
            bat 'git config user.email "nada.6.omri@gmail.com"'

            // Add and commit changes
            bat "git add ${KUBERNETES_FILE}"
            bat 'git commit -m "Update Kubernetes image tag to ${BUILD_TAG}"'

            // Push changes
            bat 'git push origin main'
          }

          // Clean up - remove the cloned repository
          bat "rmdir /s /q ${KUBERNETES_REPO_DIR}"
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
