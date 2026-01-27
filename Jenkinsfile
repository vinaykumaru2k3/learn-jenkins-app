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
                    junit 'reports/test-results.xml'
                }
                success {
                    echo 'test stage completed successfully.'
                }
                failure {
                    echo 'test stage failed.'
                }
            }
        }
    }
}
