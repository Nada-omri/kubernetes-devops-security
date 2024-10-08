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
        }

        stage('Mutation Tests - PIT') {
            steps {
                bat "mvn org.pitest:pitest-maven:mutationCoverage"
            }
        }

        stage('Sonarqube-SAST') {
            steps {
                bat "mvn clean verify sonar:sonar -Dsonar.projectKey=dev -Dsonar.projectName='devsecops' -Dsonar.host.url=http://192.168.1.64:9000 -Dsonar.token=sqp_1e5943d8aba71ee7e863c6dd548707131514fdca"
            }
        }

        stage('Vulnerability Scan - Docker') {
            parallel {
                stage('Dependency Scan') {
                    steps {
                        bat "mvn dependency-check:check"
                    }
                }
                stage('Trivy Scan - Docker') {
                    steps {
                        script {
                            // Define the Docker image to be scanned
                            def dockerImageName = 'adoptopenjdk/openjdk8:alpine-slim'
                            echo "Scanning Docker Image: ${dockerImageName}"

                            // Run Trivy scan for HIGH severity vulnerabilities on the Docker image
                            def highScanCommand = "docker run --rm aquasec/trivy:0.17.2 image --exit-code 0 --severity HIGH --light ${dockerImageName}"
                            def highScanExitCode = bat(script: highScanCommand, returnStatus: true)

                            // Run Trivy scan for CRITICAL severity vulnerabilities on the Docker image
                            def criticalScanCommand = "docker run --rm aquasec/trivy:0.17.2 image --exit-code 1 --severity CRITICAL --light ${dockerImageName}"
                            def criticalScanExitCode = bat(script: criticalScanCommand, returnStatus: true)

                            // Check the scan results for critical vulnerabilities
                            if (criticalScanExitCode != 0) {
                                error "Image scanning failed. CRITICAL vulnerabilities found."
                            } else {
                                echo "Image scanning passed. No CRITICAL vulnerabilities found."
                            }
                        }
                    }
                }
                stage('OPA Conftest') {
                    steps {
                        script {
                            def workspacePath = env.WORKSPACE.replace('\\', '/')
                            def conftestCommand = "docker run --rm -v ${workspacePath}:/project openpolicyagent/conftest test --policy opa-security.rego Dockerfile"
                            bat conftestCommand
                        }
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

        stage('Vulnerability Scan - Kubernetes') {
            parallel {
                stage('OPA conftest') {
                    steps {
                        script {
                            def workspacePath = env.WORKSPACE.replace('\\', '/')
                            def conftestCommand = "docker run --rm -v ${workspacePath}:/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml"
                            bat conftestCommand
                        }
                    }
                }
                stage('KubeSec Scan') {
                    steps {
                        script {
                            // Run the PowerShell script for KubeSec scanning
                            bat "powershell -ExecutionPolicy Bypass -File kubesec-scan.ps1"
                        }
                    }
                }
                stage('Trivy Scan - Kubernetes') {
                    steps {
                        script {
                            // Run Trivy scan for HIGH severity vulnerabilities on the Docker image
                            def highScanCommand = "docker run --rm aquasec/trivy:0.17.2 image --exit-code 0 --severity HIGH --light nadaomri/${DOCKER_IMAGE}:${BUILD_TAG}"
                            def highScanExitCode = bat(script: highScanCommand, returnStatus: true)

                            // Run Trivy scan for CRITICAL severity vulnerabilities on the Docker image
                            def criticalScanCommand = "docker run --rm aquasec/trivy:0.17.2 image --exit-code 0 --severity CRITICAL --light nadaomri/${DOCKER_IMAGE}:${BUILD_TAG}"
                            def criticalScanExitCode = bat(script: criticalScanCommand, returnStatus: true)

                            // Check the scan results for critical vulnerabilities
                            if (criticalScanExitCode != 0) {
                                error "Image scanning failed. CRITICAL vulnerabilities found."
                            } else {
                                echo "Image scanning passed. No CRITICAL vulnerabilities found."
                            }
                        }
                    }
                }
            }
        }

        stage('Update Kubernetes File with Groovy') {
            steps {
                script {
                    // Read the content of the Kubernetes YAML file
                    def kubernetesFile = readFile("${KUBERNETES_FILE}")
                    // Replace the image in the file
                    def updatedKubernetesFile = kubernetesFile.replaceAll(/(image:\s*nadaomri\/devsecops:).+/, "image: nadaomri/${DOCKER_IMAGE}:${BUILD_TAG}")
                    // Rewrite the file with the updated content
                    writeFile file: "${KUBERNETES_FILE}", text: updatedKubernetesFile
                }
            }
        }

        stage('K8S Deployment - DEV') {
            steps {
                script {
                    withKubeConfig([credentialsId: 'minikube-server2']) {
                        // Apply the updated Kubernetes deployment
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
