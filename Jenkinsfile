pipeline {
    agent any // All stages will run on the main Jenkins pod

    environment {
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub'
        IMAGE_NAME               = 'samolubode/petclinic' 
        KUBERNETES_DEPLOYMENT    = 'petclinic-deployment'
        KUBERNETES_NAMESPACE     = 'default'
        IMAGE_TAG                = "v${env.BUILD_ID}" 
    }

    // --- START FIX ---
    // Tell Jenkins to install BOTH the correct JDK and Maven.
    // This will put 'java' (version 25) and 'mvn' (version 3.9.8)
    // into the PATH for all stages.
    tools {
        maven 'Maven-3.9.8'
        jdk 'JDK-25'
    }
    // --- END FIX ---

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
            steps {
                echo 'Building the project...'
                
                // Add execute permission to the Maven wrapper
                sh 'chmod +x mvnw'
                
                // Run the build command. 
                // The './mvnw' script will now find the correct JDK
                // (from the 'tools' block) in its PATH.
                sh './mvnw clean install -DskipTests'
            }
        }

        // --- 3. TEST (Task 3) ---
        stage('Test') {
            steps {
                echo 'Running unit tests...'
                
                sh 'chmod +x mvnw'
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
            // This stage runs on 'agent any', which is fine
            // because your 'jenkins/docker:lts' image already has the Docker client.
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
            // The 'kubectl' command is available because you installed
            // the 'Kubernetes CLI' plugin, which uses the pod's
            // ServiceAccount ('jenkins-admin') automatically.
            steps {
                echo "Deploying ${IMAGE_NAME}:${IMAGE_TAG} to Kubernetes..."
                
                // Find the 'image:' line in our manifest and replace it
                // with our new, unique image tag
                sh "sed -i 's|image: .*|image: ${IMAGE_NAME}:${IMAGE_TAG}|' petclinic-frontend.yaml"

                // Apply the updated manifest
                sh "kubectl apply -f ./k8s/postgres-backend.yaml"
                sh "kubectl apply -f ./k8s/petclinic-frontend.yaml"
                
                echo "Waiting for deployment to complete..."
                sh "kubectl rollout status deployment/${KUBERNETES_DEPLOYMENT} -n ${KUBERNETES_NAMESPACE}"
                
                echo 'Deployment successful!'
            }
        }
    }
}
