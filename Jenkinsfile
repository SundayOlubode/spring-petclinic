pipeline {
    // This pipeline will run on the main Jenkins pod ('agent any'),
    // which, thanks to our custom Dockerfile, now has
    // Java, Docker, and kubectl all in one place.
    agent any

    // Use the Tools you configured in "Manage Jenkins > Tools"
    tools {
        // This will install JDK 25 on-the-fly
        jdk 'JDK-25'
        // This will install Maven 3.9.8 on-the-fly
        maven 'Maven-3.9.8'
    }

    environment {
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub-credentials'
        IMAGE_NAME               = 'samolubode/petclinic' 
        KUBERNETES_DEPLOYMENT    = 'petclinic-deployment'
        KUBERNETES_NAMESPACE     = 'devops-tools'
        // Create a unique image tag for every build
        IMAGE_TAG                = "v${env.BUILD_ID}"
    }

    stages {
        // --- 1. CHECKOUT ---
        // stage('Checkout') {
        //     steps {
        //         echo 'Checking out code from GitHub...'
        //         checkout scm
        //     }
        // }

        // // --- 2. BUILD ---
        // stage('Build') {
        //     steps {
        //         echo 'Building the project...'
                
        //         // Add execute permission to the Maven wrapper
        //         sh 'chmod +x mvnw'
                
        //         // Run the build. This will use the JDK and Maven
        //         // that the 'tools' block provided.
        //         sh './mvnw clean install -DskipTests'
        //     }
        // }

        // // --- 3. TEST ---
        // stage('Test') {
        //     steps {
        //         echo 'Running unit tests...'
        //         // We need permission again
        //         sh 'chmod +x mvnw'
        //         sh './mvnw test'
        //     }
        // }

        // // --- 4. STATIC ANALYSIS (Placeholder) ---
        // stage('Static Analysis (SonarQube)') {
        //     steps {
        //         echo 'SonarQube stage: Not configured. Skipping.'
        //     }
        // }

        // --- 5. BUILD & PUSH IMAGE ---
        // stage('Build & Push Image') {
        //     steps {
        //         echo "Building image: ${IMAGE_NAME}:${IMAGE_TAG}"
                
        //         // This 'script' block is still needed for Groovy code
        //         script {
        //             // This command will work now because our custom
        //             // image has the 'docker' client installed.
        //             docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIALS_ID) {
                        
        //                 // Build the image from the Dockerfile in our repo
        //                 def appImage = docker.build(IMAGE_NAME, "--tag ${IMAGE_NAME}:${IMAGE_TAG} .")
                        
        //                 echo "Pushing image..."
        //                 appImage.push()
        //             }
        //         }
        //     }
        // }

        // --- 6. DEPLOY TO KUBERNETES ---
        stage('Deploy to Kubernetes') {
            steps {
                echo "Deploying ${IMAGE_NAME}:${IMAGE_TAG} to Kubernetes..."
                
                // --- THIS IS THE FIX ---
                // By providing NO arguments, the plugin will automatically
                // use the pod's 'jenkins-admin' ServiceAccount.
                withKubeConfig {
                // --- END FIX ---
                    
                    // Note: Your petclinic YAMLs are in a 'k8s/' subfolder
                    sh "sed -i 's|image: .*|image: ${IMAGE_NAME}:${IMAGE_TAG}|' k8s/petclinic-frontend.yaml"

                    // Apply the backend (in case it's not there)
                    sh "kubectl apply -f k8s/postgres-backend.yaml"

                    // Apply the updated frontend
                    sh "kubectl apply -f k8s/petclinic-frontend.yaml"
                    
                    echo "Waiting for deployment to complete..."
                    sh "kubectl rollout status deployment/${KUBERNETES_DEPLOYMENT} -n ${KUBERNETES_NAMESPACE}"
                    
                    echo 'Deployment successful!'
                }
            }
        }
    }
}