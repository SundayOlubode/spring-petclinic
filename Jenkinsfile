pipeline {
    agent none // All stages will run on the main Jenkins pod

    environment {
        DOCKERHUB_CREDENTIALS_ID = 'dockerhub'
        IMAGE_NAME               = 'samolubode/petclinic' 
        KUBERNETES_DEPLOYMENT    = 'petclinic-deployment'
        KUBERNETES_NAMESPACE     = 'default'
        K8S_JENKIN_ID            = 'kubectl-jenkins-token'
        SERVER_URL               = 'https://192.168.56.10:6443'
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

}