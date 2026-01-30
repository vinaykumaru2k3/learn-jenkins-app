pipeline {
    agent any

    environment {
        NETLIFY_SITE_ID = 'ca60b834-04f6-4fb5-9a4f-4bfffe4793f2'
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')
        NODE_IMAGE = 'node:18-alpine'
        PLAYWRIGHT_IMAGE = 'my-playwright'
        REACT_APP_VERSION = "1.0.$BUILD_ID"
    }

    stages {

        stage('Install & Build') {
            agent {
                docker {
                    image "${NODE_IMAGE}"
                    reuseNode true
                }
            }
            steps {
                sh '''
                    npm ci
                    npm run build
                '''
                stash name: 'node_modules', includes: 'node_modules/**'
                stash name: 'build', includes: 'build/**'
            }
        }

        stage('Tests') {
            parallel {

                stage('Unit Tests') {
                    agent {
                        docker {
                            image "${NODE_IMAGE}"
                            reuseNode true
                        }
                    }
                    steps {
                        unstash 'node_modules'
                        sh '''
                            CI=true npm test -- --watchAll=false
                        '''
                    }
                }

                stage('Local E2E') {
                    agent {
                        docker {
                            image "${PLAYWRIGHT_IMAGE}"
                            reuseNode true
                        }
                    }
                    steps {
                        unstash 'node_modules'
                        unstash 'build'
                        sh '''
                            serve -s build -l 3000 &
                            sleep 10

                            CI_ENVIRONMENT_URL="http://localhost:3000" \
                            npx playwright test \
                              --reporter=html \
                              --output=playwright-report-local
                        '''
                    }
                    post {
                        always {
                            publishHTML([
                                allowMissing: false,
                                alwaysLinkToLastBuild: false,
                                keepAll: true,
                                reportDir: 'playwright-report-local',
                                reportFiles: 'index.html',
                                reportName: 'Local E2E'
                            ])
                        }
                    }
                }
            }
        }

        stage('Deploy Staging') {
            agent {
                docker {
                    image "${PLAYWRIGHT_IMAGE}"
                    reuseNode true
                }
            }
            steps {
                unstash 'node_modules'
                unstash 'build'
                sh '''
                    echo "Deploying to staging..."

                    netlify deploy \
                      --dir=build \
                      --auth=$NETLIFY_AUTH_TOKEN \
                      --site=$NETLIFY_SITE_ID \
                      --json > deploy-output.json

                    DEPLOY_URL=$(node -e "console.log(require('./deploy-output.json').deploy_url)")

                    if [ -z "$DEPLOY_URL" ]; then
                        echo "ERROR: deploy_url not found"
                        cat deploy-output.json
                        exit 1
                    fi

                    echo "Running E2E on $DEPLOY_URL"

                    CI_ENVIRONMENT_URL="$DEPLOY_URL" \
                    npx playwright test \
                      --reporter=html \
                      --output=playwright-report-staging
                '''
            }
            post {
                always {
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: false,
                        keepAll: true,
                        reportDir: 'playwright-report-staging',
                        reportFiles: 'index.html',
                        reportName: 'Staging E2E'
                    ])
                }
            }
        }

        stage('Deploy Prod') {
            agent {
                docker {
                    image "${PLAYWRIGHT_IMAGE}"
                    reuseNode true
                }
            }
            environment {
                CI_ENVIRONMENT_URL = 'https://velvety-frangipane-2c6406.netlify.app'
            }
            steps {
                unstash 'node_modules'
                unstash 'build'
                sh '''
                    echo "Deploying to production..."

                    netlify deploy \
                      --dir=build \
                      --prod \
                      --auth=$NETLIFY_AUTH_TOKEN \
                      --site=$NETLIFY_SITE_ID

                    npx playwright test \
                      --reporter=html \
                      --output=playwright-report-prod
                '''
            }
            post {
                always {
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: false,
                        keepAll: true,
                        reportDir: 'playwright-report-prod',
                        reportFiles: 'index.html',
                        reportName: 'Prod E2E'
                    ])
                }
            }
        }
    }
}
