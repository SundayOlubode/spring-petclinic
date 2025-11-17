// Sample 1: Kubernetes Agent (Pod-per-Stage)
pipeline {
    agent none

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
            agent any
            steps {
                echo 'Checking out code from GitHub...'
                checkout scm
            }
        }

        // BUILD
        stage('Build') {
            agent {
                kubernetes {
                    cloud 'kubernetes'
                    // V-- UPDATED TO YAML --V
                    yaml """
                    apiVersion: v1
                    kind: Pod
                    spec:
                      containers:
                      - name: maven
                        image: maven:3.9.8-eclipse-temurin-21
                        command: ['cat']
                        tty: true
                        volumeMounts:
                          - name: maven-cache
                            mountPath: /root/.m2
                      volumes:
                        - name: maven-cache
                          persistentVolumeClaim:
                            claimName: jenkins-maven-cache
                    """
                // ^-- UPDATED TO YAML --^
                }
            }
            steps {
                // Must specify the container name here
                container('maven') {
                    echo 'Building the project...'
                    sh 'chmod +x mvnw'
                    sh './mvnw clean install -DskipTests'
                }
            }
        }

        // TEST
        stage('Test') {
            agent {
                kubernetes {
                    cloud 'kubernetes'
                    // V-- UPDATED TO YAML --V
                    yaml """
                    apiVersion: v1
                    kind: Pod
                    spec:
                      containers:
                      - name: maven
                        image: maven:3.9.8-eclipse-temurin-21
                        command: ['cat']
                        tty: true
                        volumeMounts:
                          - name: maven-cache
                            mountPath: /root/.m2
                      volumes:
                        - name: maven-cache
                          persistentVolumeClaim:
                            claimName: jenkins-maven-cache
                    """
                // ^-- UPDATED TO YAML --^
                }
            }
            steps {
                container('maven') {
                    echo 'Running unit tests...'
                    sh 'chmod +x mvnw'
                    sh './mvnw test'
                }
            }
        }

        // STATIC ANALYSIS
        stage('Sonar Code Analysis') {
            agent {
                kubernetes {
                    cloud 'kubernetes'
                    // V-- UPDATED TO YAML --V
                    yaml """
                    apiVersion: v1
                    kind: Pod
                    spec:
                      containers:
                      - name: maven
                        image: maven:3.9.8-eclipse-temurin-21
                        command: ['cat']
                        tty: true
                        volumeMounts:
                          - name: maven-cache
                            mountPath: /root/.m2
                      volumes:
                        - name: maven-cache
                          persistentVolumeClaim:
                            claimName: jenkins-maven-cache
                    """
                // ^-- UPDATED TO YAML --^
                }
            }
            steps {
                container('maven') {
                    withSonarQubeEnv('sonarserver') {
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
        }

        // BUILD & PUSH IMAGE
        // This stage was already correct and did not need changes
        stage('Build & Push Image') {
            agent {
                kubernetes {
                    cloud 'kubernetes'
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
                          - name: docker-config
                            mountPath: /kaniko/.docker/
                      volumes:
                        - name: docker-config
                          secret:
                            secretName: ${DOCKERHUB_CREDENTIALS_ID}
                            items:
                              - key: .dockerconfigjson
                                path: config.json
                    """
                }
            }
            steps {
                container('kaniko') {
                    echo "Building image: ${IMAGE_NAME}:${IMAGE_TAG}"
                    sh """
                    /kaniko/executor \
                      --context \${WORKSPACE} \
                      --dockerfile \${WORKSPACE}/Dockerfile \
                      --destination ${IMAGE_NAME}:${IMAGE_TAG} \
                      --destination ${IMAGE_NAME}:latest
                    """
                }
            }
        }

        // DEPLOY TO KUBERNETES
        stage('Deploy to Kubernetes') {
            agent {
                kubernetes {
                    cloud 'kubernetes'
                    // V-- UPDATED TO YAML --V
                    yaml """
                    apiVersion: v1
                    kind: Pod
                    spec:
                      containers:
                      - name: kubectl
                        image: bitnami/kubectl:latest
                        command: ['cat']
                        tty: true
                    """
                // ^-- UPDATED TO YAML --^
                }
            }
            steps {
                container('kubectl') {
                    echo "Deploying ${IMAGE_NAME}:${IMAGE_TAG} to Kubernetes..."
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
}
