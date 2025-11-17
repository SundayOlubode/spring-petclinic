pipeline {
    agent {
        docker {
            // This must be a custom "fat" image you have built
            // that contains: JDK, Maven, Docker CLI, and Kubectl.
            image 'samolubode/jenkins-docker-k8s:lts'

            // This mounts the host's Docker socket,
            // allowing the container to run 'docker' commands.
            // We also mount a volume for Maven caching.
            args '-v /var/run/docker.sock:/var/run/docker.sock ...'
        }
    }

    // Tools
    tools {
        // jdk 'JDK-25'
        // maven 'Maven-3.9.8'
        nodejs 'NodeJS-20'
    }

    environment {
        DOCKERHUB_CREDENTIALS_ID = 'docker'
        IMAGE_NAME               = 'samolubode/petclinic'
        KUBERNETES_DEPLOYMENT    = 'petclinic-deployment'
        KUBERNETES_NAMESPACE     = 'devops-tools'
        // Unique image tag for every build
        IMAGE_TAG                = "v${env.BUILD_ID}"
    }

    stages {
        // CHECKOUT
        stage('Checkout') {
            steps {
                echo 'Checking out code from GitHub...'
                // This automatically pulls the code from the repo
                // configured in the Jenkins job
                checkout scm
            }
        }

        // BUILD
        // This stage runs on the main agent, which now has
        // the correct JDK and Maven from the 'tools' block.
        stage('Build') {
            steps {
                sh 'node -v'
                echo 'Building the project...'

                // Add execute permission to the Maven wrapper
                sh 'chmod +x mvnw'

                // Run the build. This will use the JDK and Maven
                // that the 'tools' block provides.
                sh './mvnw clean install -DskipTests'
            }
        }

        // TEST
        stage('Test') {
            steps {
                echo 'Running unit tests...'
                sh 'chmod +x mvnw'
                // This will use the JDK and Maven from the 'tools' block
                sh './mvnw test'
            }
        }

        // STATIC ANALYSIS
        stage('Sonar Code Analysis') {
            environment {
                scannerHome = tool 'Sonar7.3'
            }
            steps {
                withSonarQubeEnv('sonarserver') {
                    sh """
                        ${scannerHome}/bin/sonar-scanner \
                        -Dsonar.projectKey=SundayOlubode_spring-petclinic \
                        -Dsonar.organization=samolubode \
                        -Dsonar.host.url=https://sonarcloud.io \
                        -Dsonar.projectName=spring-petclinic \
                        -Dsonar.projectVersion=1.0 \
                        -Dsonar.sources=src/ \
                        -Dsonar.java.binaries=target/classes/ \
                        -Dsonar.junit.reportsPath=target/surefire-reports/ \
                        -Dsonar.jacoco.reportsPath=target/jacoco.exec
                    """
                }
            }
        }

        // BUILD & PUSH IMAGE
        stage('Build & Push Image') {
            steps {
                echo "Building image: ${IMAGE_NAME}:${IMAGE_TAG}"

                script {
                    // Log in to Docker Hub using the credential ID
                    docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIALS_ID) {
                        // Build the image and give it the unique tag
                        def appImage = docker.build("${IMAGE_NAME}:${IMAGE_TAG}", '.')

                        // Push the unique tag (e.g., v38)
                        echo "Pushing image: ${IMAGE_NAME}:${IMAGE_TAG}"
                        appImage.push()

                        // Also update the 'latest' tag
                        echo "Pushing image: ${IMAGE_NAME}:latest"
                        appImage.push('latest')
                    }
                }
            }
        }

        // DEPLOY TO KUBERNETES
        stage('Deploy to Kubernetes') {
            steps {
                echo "Deploying ${IMAGE_NAME}:${IMAGE_TAG} to Kubernetes..."

                // Use withKubeConfig - automatically find and use the pod's
                // 'jenkins-admin' ServiceAccount token.
                withKubeConfig {
                    // This command updates the image tag in the file
                    sh "sed -i 's|image: .*|image: ${IMAGE_NAME}:${IMAGE_TAG}|' k8s/petclinic-frontend.yaml"

                    // Apply the backend (in case it's not there)
                    sh 'kubectl apply -f k8s/postgres-backend.yaml'

                    // Apply the updated frontend
                    sh 'kubectl apply -f k8s/petclinic-frontend.yaml'

                    echo 'Waiting for deployment to complete...'
                    // Wait for the new pods to become 'Ready'
                    sh "kubectl rollout status deployment/${KUBERNETES_DEPLOYMENT} -n ${KUBERNETES_NAMESPACE}"

                    echo 'Deployment successful!'
                }
            }
        }
    }
}
