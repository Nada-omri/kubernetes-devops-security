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
        }

        stage('Mutation Tests - PIT') {
            steps {
                bat "mvn org.pitest:pitest-maven:mutationCoverage"
            }
        }

        stage('Sonarqube-SAST') {
            steps {
                bat "mvn clean verify sonar:sonar -Dsonar.projectKey=dev -Dsonar.projectName='devsecops' -Dsonar.host.url=http://192.168.1.18:9000 -Dsonar.token=sqp_1e5943d8aba71ee7e863c6dd548707131514fdca"
            }
        }

        stage('Extract Base Image from Dockerfile') {
            steps {
                script {
                    // Extract the base image name from the Dockerfile
                    def dockerFilePath = 'Dockerfile'
                    def baseImage = bat(script: "powershell -Command \"Select-String -Pattern '^FROM ' ${dockerFilePath} | ForEach-Object { $_.ToString().Split(' ')[1] }\"", returnStdout: true).trim()
                    env.BASE_IMAGE = baseImage
                    echo "Base image extracted: ${env.BASE_IMAGE}"
                }
            }
        }

        stage('Trivy Scan') {
            steps {
                script {
                    // Scan the base image using Trivy
                    bat "docker pull ${env.BASE_IMAGE}"
                    bat "docker run --rm -v %WORKSPACE%:/root/.cache/ aquasec/trivy:0.17.2 image --exit-code 1 --severity HIGH ${env.BASE_IMAGE}"
                    bat "docker run --rm -v %WORKSPACE%:/root/.cache/ aquasec/trivy:0.17.2 image --exit-code 1 --severity CRITICAL ${env.BASE_IMAGE}"

                    def exitCode = currentBuild.rawBuild.getResult() == 'FAILURE' ? 1 : 0
                    echo "Trivy scan exit code: ${exitCode}"
                    if (exitCode != 0) {
                        error("Image scanning failed. Vulnerabilities found.")
                    } else {
                        echo "Image scanning passed. No vulnerabilities found."
                    }
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

        stage('Update Kubernetes File with Groovy') {
            steps {
                script {
                    def kubernetesFile = readFile("${KUBERNETES_FILE}")
                    def updatedKubernetesFile = kubernetesFile.replaceAll(/(image:\s*nadaomri\/devsecops:).+/, "image: nadaomri/${DOCKER_IMAGE}:${BUILD_TAG}")
                    writeFile file: "${KUBERNETES_FILE}", text: updatedKubernetesFile
                }
            }
        }

        stage('K8S Deployment - DEV') {
            steps {
                script {
                    withKubeConfig([credentialsId: 'kubeconfig-credential']) {
                        bat "kubectl -n default apply -f ${KUBERNETES_FILE}"
                    }
                }
            }
        }
    }

    post {
        always {
            dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
            pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
            junit 'target/surefire-reports/*.xml'
            jacoco execPattern: 'target/jacoco.exec'
        }

        success {
            echo 'Pipeline completed successfully!'
        }

        failure {
            echo 'Pipeline failed!'
        }
    }
}
