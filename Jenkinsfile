pipeline {
  agent any

  environment {
    DOCKERHUB_CREDENTIALS_ID = 'dockerhub'
    IMAGE_NAME               = 'samolubode/petclinic'
    IMAGE_TAG                = "v${env.BUILD_ID}"
    K8S_JENKIN_ID            = 'kubectl-jenkins-token'
    SERVER_URL               = 'https://192.168.56.10:6443'
    KUBERNETES_DEPLOYMENT    = 'petclinic-deployment'
    KUBERNETES_NAMESPACE     = 'devops-tools'
  }

  tools {
    maven 'Maven-3.9.8'
    jdk 'JDK-25'
  }

  stages {

    // --- 1. Checkout code from GitHub ---
    // stage('Checkout') {
    //   steps {
    //     echo 'Checking out code from GitHub...'
    //     checkout scm
    //   }
    // }

    // --- 2. Build application ---
    // stage('Build') {
    //   steps {
    //     echo 'Building the project...'
    //     sh 'chmod +x mvnw'
    //     sh './mvnw clean package -DskipTests'
    //   }
    // }

    // --- 3. Test application ---
    // stage('Test') {
    //   steps {
    //     echo 'Running unit tests...'
    //     sh './mvnw test'
    //   }
    // }

    // --- 4. Build & Push Docker image ---
    // stage('Build & Push Image') {
    //   steps {
    //     echo "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
    //     script {
    //       docker.withRegistry('https://index.docker.io/v1/', DOCKERHUB_CREDENTIALS_ID) {
    //         def appImage = docker.build("${IMAGE_NAME}:${IMAGE_TAG}")
    //         echo 'Pushing image to Docker Hub...'
    //         appImage.push()
    //       }
    //     }
    //   }
    // }

    // --- 5. Deploy to Kubernetes ---
    stage('Deploy to Kubernetes') {
      agent {
        kubernetes {
          yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kubectl
    image: bitnami/kubectl:1.31-debian-12
    command:
    - cat
    tty: true
"""
        }
      }
      steps {
        echo "Deploying ${IMAGE_NAME}:${IMAGE_TAG} to Kubernetes..."
        container('kubectl') {
          withKubeConfig([
            credentialsId: K8S_JENKIN_ID,
            serverUrl: SERVER_URL,
            namespace: KUBERNETES_NAMESPACE
          ]) {
            // Update deployment manifests with the new image tag
            sh "sed -i 's|image: .*|image: ${IMAGE_NAME}:${IMAGE_TAG}|' k8s/petclinic-frontend.yaml"

            // Apply manifests
            sh 'kubectl apply -f k8s/postgres-backend.yaml'
            sh 'kubectl apply -f k8s/petclinic-frontend.yaml'

            // Wait for rollout
            sh "kubectl rollout status deployment/${KUBERNETES_DEPLOYMENT} -n ${KUBERNETES_NAMESPACE}"

            echo '✅ Deployment completed successfully!'
          }
        }
      }
    }
  }

  post {
    always {
      echo 'Pipeline finished. Cleaning up workspace...'
      cleanWs()
    }
    failure {
      echo '❌ Pipeline failed. Please check logs above.'
    }
  }
}
