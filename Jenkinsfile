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
        namespace: "devops-tools"
      ]) {
        sh 'kubectl version --client'
        sh 'kubectl get pods -n devops-tools'
      }
    }
  }
}
