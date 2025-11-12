pipeline {
    // This pipeline will run on the main Jenkins pod
    agent any

    environment {
        // --- CONFIGURATION ---
        // The ID you gave your Docker Hub credentials in Jenkins
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub-credentials'
        
        // Your Docker Hub username + repository name
        // (e.g., 'samolubode/petclinic')
        IMAGE_NAME = 'samolubode/petclinic' 

        // The name of your Petclinic deployment in Kubernetes
        KUBERNETES_DEPLOYMENT = 'petclinic-deployment'
        
        // The namespace your Petclinic app is in
        // (You used 'default' in our previous chat)
        KUBERNETES_NAMESPACE  = 'default'
        // --- END CONFIGURATION ---

        // This tag will be unique for every build (e.g., "v1", "v2", etc.)
        IMAGE_TAG = "v${env.BUILD_ID}"
    }

    stages {
        // --- TASK 3: CHECKOUT ---
        stage('Checkout') {
            steps {
                echo 'This is a new line to force a build!'
            }
            
            steps {
                echo 'Checking out code from GitHub...'
                // This automatically pulls the code from the repo
                // you configured in the Jenkins job
                checkout scm
            }
        }

        // --- TASK 3: TEST ---
        stage('Test') {
            // This stage runs inside a separate container that
            // has Maven and Java 17 installed.
            agent {
                docker {
                    image 'maven:3.8-openjdk-17' 
                }
            }
            steps {
                echo 'Running unit tests...'
                // This assumes your project has the Maven wrapper (mvnw)
                // If not, you can just use: sh 'mvn test'
                sh './mvnw test'
            }
        }

        // --- TASK 3: STATIC ANALYSIS (PLACEHOLDER) ---
        stage('Static Analysis (SonarQube)') {
            // This is a placeholder as required by the lab sheet.
            // A real setup would require a SonarQube server.
            steps {
                echo 'SonarQube stage: Not configured. Skipping.'
            }
        }

        // --- TASK 3: BUILD & PUSH IMAGE ---
        // stage('Build & Push Image') {
        //     // This stage MUST have access to a Docker daemon.
        //     // (See the critical note below this file)
        //     steps {
        //         echo "Building image: ${IMAGE_NAME}:${IMAGE_TAG}"
                
        //         // Use the Docker Pipeline plugin to log in to Docker Hub
        //         docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIALS_ID) {
                    
        //             // 1. Build the image
        //             // The 'docker.build' command needs the image name AND
        //             // the build context ('.' means the current directory)
        //             def appImage = docker.build(IMAGE_NAME, "--tag ${IMAGE_NAME}:${IMAGE_TAG} .")
                    
        //             // 2. Push the image
        //             echo "Pushing image..."
        //             appImage.push()
        //         }
        //     }
        // }

        // // --- TASK 4: DEPLOY TO KUBERNETES ---
        // stage('Deploy to Kubernetes') {
        //     // This stage uses the Kubernetes CLI plugin, which will
        //     // automatically use the 'jenkins-admin' ServiceAccount.
        //     steps {
        //         echo "Deploying ${IMAGE_NAME}:${IMAGE_TAG} to Kubernetes..."
                
        //         // 1. Update the image in our deployment manifest.
        //         // This is a simple 'find-and-replace' on the file.
        //         // It finds the line 'image: ...' and replaces it.
        //         sh "sed -i 's|image: .*|image: ${IMAGE_NAME}:${IMAGE_TAG}|' petclinic-frontend.yaml"

        //         // 2. Apply the updated manifest to the cluster
        //         sh "kubectl apply -f petclinic-frontend.yaml"
                
        //         // 3. Wait for the rollout to complete (for Task 5)
        //         echo "Waiting for deployment to complete..."
        //         sh "kubectl rollout status deployment/${KUBERNETES_DEPLOYMENT} -n ${KUBERNETES_NAMESPACE}"
                
        //         echo 'Deployment successful!'
        //     }
        // }
    }
}