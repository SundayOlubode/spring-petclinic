pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub-credentials'
        IMAGE_NAME               = 'samolubode/petclinic' 
        KUBERNETES_DEPLOYMENT    = 'petclinic-deployment'
        KUBERNETES_NAMESPACE     = 'default'
        IMAGE_TAG                = "v${env.BUILD_ID}"
    }

    stages {
        // --- 1. CHECKOUT (Task 3) ---
        stage('Checkout') {
            steps {
                echo 'Checking out code from GitHub...'
                checkout scm
            }
        }

        // --- 2. BUILD (Task 3) ---
        stage('Build') {
            agent {
                docker { image 'maven:3-eclipse-temurin-25' }
            }
            steps {
                echo 'Building the project...'
                
                // Add execute permission to the Maven wrapper
                sh 'chmod +x mvnw'
                
                // Now, run the build command
                sh './mvnw clean install -DskipTests'
            }
        }

        // --- 3. TEST (Task 3) ---
        stage('Test') {
            agent {
                docker { image 'maven:3-eclipse-temurin-25' }
            }
            steps {
                echo 'Running unit tests...'
                
                // We need to add permission again because this
                // is a new agent with a fresh checkout.
                sh 'chmod +x mvnw'

                // Now, run the test command
                sh './mvnw test'
            }
        }

        // --- 4. STATIC ANALYSIS (Task 3 Placeholder) ---
        stage('Static Analysis (SonarQube)') {
            steps {
                echo 'SonarQube stage: Not configured. Skipping.'
            }
        }

        // --- 5. BUILD & PUSH IMAGE (Task 3) ---
        stage('Build & Push Image') {
            steps {
                echo "Building image: ${IMAGE_NAME}:${IMAGE_TAG}"
                
                script {
                    docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIALS_ID) {
                        
                        // Build the image from the Dockerfile in our repo
                        def appImage = docker.build(IMAGE_NAME, "--tag ${IMAGE_NAME}:${IMAGE_TAG} .")
                        
                        echo "Pushing image..."
                        appImage.push()
                    }
                }
            }
        }

        // --- 6. DEPLOY TO KUBERNETES (Task 4) ---
        stage('Deploy to Kubernetes') {
            steps {
                echo "Deploying ${IMAGE_NAME}:${IMAGE_TAG} to Kubernetes..."
                
                // Find the 'image:' line in our manifest and replace it
                // with our new, unique image tag
                sh "sed -i 's|image: .*|image: ${IMAGE_NAME}:${IMAGE_TAG}|' petclinic-frontend.yaml"

                // Apply the updated manifest
                sh "kubectl apply -f petclinic-frontend.yaml"
                
                echo "Waiting for deployment to complete..."
                sh "kubectl rollout status deployment/${KUBERNETES_DEPLOYMENT} -n ${KUBERNETES_NAMESPACE}"
                
                echo 'Deployment successful!'
            }
        }
    }
}