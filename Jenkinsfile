pipeline {
    // This pipeline will run on the main Jenkins pod ('agent any').
    // This pod (from jenkins-03-deployment.yaml) runs our custom
    // samolubode/jenkins-k8s:latest image, which has docker + kubectl.
    agent any

    // Use the Tools you configured in "Manage Jenkins > Tools"
    tools {
        // This will install JDK 25 on-the-fly
        jdk 'JDK-25'
        // This will install Maven 3.9.8 on-the-fly
        maven 'Maven-3.9.8'
    }

    environment {
        // Make sure this ID matches what you created in
        // Manage Jenkins > Credentials
        DOCKERHUB_CREDENTIALS_ID = 'docker'
        IMAGE_NAME               = 'samolubode/petclinic'
        KUBERNETES_DEPLOYMENT    = 'petclinic-deployment'
        // Make sure this matches your pod's namespace
        KUBERNETES_NAMESPACE     = 'devops-tools'
        // Create a unique image tag for every build
        IMAGE_TAG                = "v${env.BUILD_ID}"
    }

    stages {
        // --- 1. CHECKOUT ---
        stage('Checkout') {
            steps {
                echo 'Checking out code from GitHub...'
                // This automatically pulls the code from the repo
                // you configured in the Jenkins job
                checkout scm
            }
        }

        // --- 2. BUILD ---
        // This stage runs on the main agent, which now has
        // the correct JDK and Maven from the 'tools' block.
        stage('Build') {
            steps {
                echo 'Building the project...'

                // Add execute permission to the Maven wrapper
                sh 'chmod +x mvnw'

                // Run the build. This will use the JDK and Maven
                // that the 'tools' block provided.
                sh './mvnw clean install -DskipTests'
            }
        }

        // --- 3. TEST ---
        stage('Test') {
            steps {
                echo 'Running unit tests...'
                // We need permission again
                sh 'chmod +x mvnw'
                // This will use the JDK and Maven from the 'tools' block
                sh './mvnw test'
            }
        }

        // --- 4. STATIC ANALYSIS (Placeholder) ---
        stage('Sonar Code Analysis') {
            environment {
                scannerHome = tool 'Sonar7.3'
            }
            steps {
                withSonarQubeEnv('sonarserver') {
                    sh """
                        ${scannerHome}/bin/sonar-scanner \
                        -Dsonar.projectKey=spring-petclinic \
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

        // --- 5. BUILD & PUSH IMAGE ---
        // This stage works because our 'agent any' pod
        // (from samolubode/jenkins-k8s:latest) has the 'docker' client.
        stage('Build & Push Image') {
            steps {
                echo "Building image: ${IMAGE_NAME}:${IMAGE_TAG}"

                // This 'script' block is needed for Groovy code
                script {
                    // Log in to Docker Hub using the credential ID
                    docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIALS_ID) {
                        // Build the image and give it the unique tag
                        def appImage = docker.build("${IMAGE_NAME}:${IMAGE_TAG}", '.')

                        // --- THIS IS THE FIX ---
                        // 1. Push the unique tag (e.g., v38)
                        echo "Pushing image: ${IMAGE_NAME}:${IMAGE_TAG}"
                        appImage.push()

                        // 2. Also update the 'latest' tag (good practice)
                        echo "Pushing image: ${IMAGE_NAME}:latest"
                        appImage.push('latest')
                    // --- END FIX ---
                    }
                }
            }
        }

        // --- 6. DEPLOY TO KUBERNETES ---
        // This stage works because our 'agent any' pod
        // (from samolubode/jenkins-k8s:latest) has the 'kubectl' client.
        stage('Deploy to Kubernetes') {
            steps {
                echo "Deploying ${IMAGE_NAME}:${IMAGE_TAG} to Kubernetes..."

                // Use withKubeConfig (note the capital 'C') to
                // automatically find and use the pod's
                // 'jenkins-admin' ServiceAccount token.
                withKubeConfig {
                    // Make sure your YAML files are in a 'k8s/' subfolder
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
