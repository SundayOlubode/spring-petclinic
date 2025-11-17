// Sample 1: Kubernetes Agent (Pod-per-Stage)
pipeline {
    // 'agent none' at the top level means each stage
    // must define its own agent.
    agent none

    // The 'tools' block is removed because tools are
    // now provided by container images, not pre-installed
    // on an agent.

    environment {
        DOCKERHUB_CREDENTIALS_ID = 'docker'
        IMAGE_NAME               = 'samolubode/petclinic'
        KUBERNETES_DEPLOYMENT    = 'petclinic-deployment'
        KUBERNETES_NAMESPACE     = 'devops-tools'
        IMAGE_TAG                = "v${env.BUILD_ID}"
    }

    stages {
        // CHECKOUT
        stage('Checkout') {
            // This first stage can run on any available agent
            // just to check out the code.
            agent any
            steps {
                echo 'Checking out code from GitHub...'
                checkout scm
            }
        }

        // BUILD
        stage('Build') {
            // This stage runs in a pod with a 'maven' container.
            // We use a Maven image that includes a JDK.
            agent {
                kubernetes {
                    cloud 'kubernetes' // Optional: specify your Jenkins K8s cloud name
                    image 'maven:3.9.8-eclipse-temurin-21'
                    // We can mount a volume for Maven caching
                    volumeMounts {
                        volume(type: 'PersistentVolumeClaim', mountPath: '/root/.m2', claimName: 'jenkins-maven-cache', readOnly: false)
                    }
                }
            }
            steps {
                echo 'Building the project...'
                sh 'chmod +x mvnw'
                // Run the build
                sh './mvnw clean install -DskipTests'
            }
        }

        // TEST
        stage('Test') {
            // This stage uses the same agent setup as the Build stage
            agent {
                kubernetes {
                    cloud 'kubernetes'
                    image 'maven:3.9.8-eclipse-temurin-21'
                    volumeMounts {
                        volume(type: 'PersistentVolumeClaim', mountPath: '/root/.m2', claimName: 'jenkins-maven-cache', readOnly: false)
                    }
                }
            }
            steps {
                echo 'Running unit tests...'
                sh 'chmod +x mvnw'
                sh './mvnw test'
            }
        }

        // STATIC ANALYSIS
        stage('Sonar Code Analysis') {
            // This also runs in the Maven container.
            // NOTE: The original's use of 'tool "Sonar7.3"' is
            // replaced with the standard Maven sonar plugin,
            // which is a more portable method.
            agent {
                kubernetes {
                    cloud 'kubernetes'
                    image 'maven:3.9.8-eclipse-temurin-21'
                    volumeMounts {
                        volume(type: 'PersistentVolumeClaim', mountPath: '/root/.m2', claimName: 'jenkins-maven-cache', readOnly: false)
                    }
                }
            }
            steps {
                withSonarQubeEnv('sonarserver') {
                    // Use the Maven plugin for Sonar, which is cleaner
                    // than using the standalone scanner tool.
                    sh '''
                        ./mvnw sonar:sonar \
                          -Dsonar.projectKey=SundayOlubode_spring-petclinic \
                          -Dsonar.organization=samolubode \
                          -Dsonar.host.url=https://sonarcloud.io \
                          -Dsonar.projectName=spring-petclinic
                    '''
                }
            }
        }

        // BUILD & PUSH IMAGE
        stage('Build & Push Image') {
            // This stage uses Kaniko to build an image inside a
            // container *without* needing a Docker daemon.
            // This is the standard, secure way to build images in K8s.
            agent {
                kubernetes {
                    cloud 'kubernetes'
                    // Define a pod with the Kaniko executor image
                    yaml """
                    apiVersion: v1
                    kind: Pod
                    spec:
                      containers:
                      - name: kaniko
                        image: gcr.io/kaniko-project/executor:latest
                        command: ['/busybox/cat']
                        tty: true
                        volumeMounts:
                          # Mount Docker credentials from a K8s secret
                          - name: docker-config
                            mountPath: /kaniko/.docker/
                      volumes:
                        - name: docker-config
                          secret:
                            secretName: ${DOCKERHUB_CREDENTIALS_ID} # Assumes K8s secret name matches credential ID
                            items:
                              - key: .dockerconfigjson
                                path: config.json
                    """
                }
            }
            steps {
                // Run the Kaniko command in the 'kaniko' container
                container('kaniko') {
                    echo "Building image: ${IMAGE_NAME}:${IMAGE_TAG}"

                    // Run the Kaniko executor
                    sh """
                    /kaniko/executor \
                      --context \${WORKSPACE} \
                      --dockerfile \${WORKSPACE}/Dockerfile \
                      --destination ${IMAGE_NAME}:${IMAGE_TAG} \
                      --destination ${IMAGE_NAME}:latest
                    """

                    echo "Pushing image: ${IMAGE_NAME}:${IMAGE_TAG}"
                    echo "Pushing image: ${IMAGE_NAME}:latest"
                }
            }
        }

        // DEPLOY TO KUBERNETES
        stage('Deploy to Kubernetes') {
            // This stage runs in a pod with just the 'kubectl' tool.
            agent {
                kubernetes {
                    cloud 'kubernetes'
                    image 'bitnami/kubectl:latest'
                }
            }
            steps {
                echo "Deploying ${IMAGE_NAME}:${IMAGE_TAG} to Kubernetes..."

                // withKubeConfig will automatically use the pod's
                // own ServiceAccount token for authentication.
                withKubeConfig() {
                    sh "sed -i 's|image: .*|image: ${IMAGE_NAME}:${IMAGE_TAG}|' k8s/petclinic-frontend.yaml"
                    sh 'kubectl apply -f k8s/postgres-backend.yaml'
                    sh 'kubectl apply -f k8s/petclinic-frontend.yaml'
                    echo 'Waiting for deployment to complete...'
                    sh "kubectl rollout status deployment/${KUBERNETES_DEPLOYMENT} -n ${KUBERNETES_NAMESPACE}"
                    echo 'Deployment successful!'
                }
            }
        }
    }
}
