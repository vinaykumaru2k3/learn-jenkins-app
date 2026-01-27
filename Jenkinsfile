pipeline {
    agent any

    stages {
        stage('Build') {
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                }
            }
            steps {
                sh '''
                ls -la
                node --version
                npm --version
                npm ci
                npm run build
                ls -la
                '''
            }
            post {
                success {
                    echo 'build stage completed successfully.'
                }
                failure {
                    echo 'build stage failed.'
                }
            }
        }

        stage('Test') {
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                }
            }
            steps {
                sh '''
                echo "Running tests..."
                test -f build/index.html || { echo "Build file not found!"; exit 1; }
                npm run test
                '''
            }
            post {
                always {
                    junit 'test-results/junit.xml'
                }
                success {
                    echo 'test stage completed successfully.'
                }
                failure {
                    echo 'test stage failed.'
                }
            }
        }

        stage('E2E Tests') {
            agent {
                docker {
                    image 'docker pull mcr.microsoft.com/playwright:v1.58.0-noble'
                    reuseNode true
                }
            }
            steps {
                sh '''
                echo "Running E2E tests..."
                npm install -g serve
                node_modules/.bin/serve -s build
                npx playwright test
                '''
            }
        }
    }
}
