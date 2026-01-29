pipeline {
    agent any

    environment {
        NETLIFY_SITE_ID = 'ca60b834-04f6-4fb5-9a4f-4bfffe4793f2'
        NETLIFY_AUTH_TOKEN = credentials('netlify-token')
        NODE_IMAGE = 'node:18-alpine'
        PLAYWRIGHT_IMAGE = 'mcr.microsoft.com/playwright:v1.39.0-jammy'
    }

    stages {

        stage('Build') {
            agent {
                docker {
                    image "${NODE_IMAGE}"
                    reuseNode true
                }
            }
            steps {
                sh '''
                    node --version
                    npm --version
                    npm ci
                    npm run build
                '''
            }
        }

        stage('Tests') {
            parallel {

                stage('Unit tests') {
                    agent {
                        docker {
                            image "${NODE_IMAGE}"
                            reuseNode true
                        }
                    }
                    steps {
                        sh '''
                            npm ci
                            CI=true npm test -- --watchAll=false
                        '''
                    }
                    post {
                        always {
                            junit 'jest-results/junit.xml'
                        }
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
                        sh '''
                            npm ci
                            npx playwright install
                            npm install serve

                            node_modules/.bin/serve -s build -l 3000 &
                            sleep 10

                            CI_ENVIRONMENT_URL="http://localhost:3000" \
                            npx playwright test --reporter=html
                        '''
                    }
                    post {
                        always {
                            publishHTML([
                                allowMissing: false,
                                alwaysLinkToLastBuild: false,
                                keepAll: false,
                                reportDir: 'playwright-report',
                                reportFiles: 'index.html',
                                reportName: 'Local E2E',
                                useWrapperFileDirectly: true
                            ])
                        }
                    }
                }
            }
        }

        stage('Deploy staging') {
            agent {
                docker {
                    image "${NODE_IMAGE}"
                    reuseNode true
                }
            }
            steps {
                sh '''
                    npm ci
                    npm install netlify-cli
                    node_modules/.bin/netlify --version

                    echo "Deploying to staging..."
                    node_modules/.bin/netlify deploy \
                      --dir=build \
                      --no-build \
                      --auth=$NETLIFY_AUTH_TOKEN \
                      --site=$NETLIFY_SITE_ID \
                      --json > deploy-output.json
                '''
            }
            post {
                success {
                    stash includes: 'deploy-output.json', name: 'deployJson'
                }
            }
        }

        stage('Staging E2E') {
            agent {
                docker {
                    image "${PLAYWRIGHT_IMAGE}"
                    reuseNode true
                }
            }
            steps {
                unstash 'deployJson'
                sh '''
                    npm ci
                    npx playwright install

                    DEPLOY_URL=$(grep -o '"deploy_url":"[^"]*"' deploy-output.json | cut -d'"' -f4)

                    case "$DEPLOY_URL" in
                      http*) ;;
                      *) DEPLOY_URL="https://$DEPLOY_URL" ;;
                    esac

                    echo "Testing against: $DEPLOY_URL"

                    CI_ENVIRONMENT_URL="$DEPLOY_URL" \
                    npx playwright test --reporter=html
                '''
            }
            post {
                always {
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: false,
                        keepAll: false,
                        reportDir: 'playwright-report',
                        reportFiles: 'index.html',
                        reportName: 'Staging E2E',
                        useWrapperFileDirectly: true
                    ])
                }
            }
        }

        stage('Approval') {
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    input message: 'Do you wish to deploy to production?', ok: 'Deploy'
                }
            }
        }

        stage('Deploy prod') {
            agent {
                docker {
                    image "${NODE_IMAGE}"
                    reuseNode true
                }
            }
            steps {
                sh '''
                    npm ci
                    npm install netlify-cli

                    echo "Deploying to production..."
                    node_modules/.bin/netlify deploy \
                      --dir=build \
                      --prod \
                      --auth=$NETLIFY_AUTH_TOKEN \
                      --site=$NETLIFY_SITE_ID
                '''
            }
        }

        stage('Prod E2E') {
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
                sh '''
                    npm ci
                    npx playwright install
                    npx playwright test --reporter=html
                '''
            }
            post {
                always {
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: false,
                        keepAll: false,
                        reportDir: 'playwright-report',
                        reportFiles: 'index.html',
                        reportName: 'Prod E2E',
                        useWrapperFileDirectly: true
                    ])
                }
            }
        }
    }
}
