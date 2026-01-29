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

                    node_modules/.bin/netlify deploy \
                      --dir=build \
                      --no-build \
                      --auth=$NETLIFY_AUTH_TOKEN \
                      --site=$NETLIFY_SITE_ID \
                      --json > deploy-output.json

                    echo "Deploy output:"
                    cat deploy-output.json
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

                    DEPLOY_URL=$(grep -o '"deploy_url":[[:space:]]*"[^"]*"' deploy-output.json | cut -d'"' -f4)

                    if [ -z "$DEPLOY_URL" ]; then
                      echo "ERROR: deploy_url not found"
                      cat deploy-output.json
                      exit 1
                    fi

                    echo "Testing against: $DEPLOY_URL"

                    CI_ENVIRONMENT_URL="$DEPLOY_URL" \
                    npx playwright test --reporter=html
                '''
            }
        }

        stage('Approval') {
            steps {
                timeout(time: 15, unit: 'MINUTES') {
                    input message: 'Deploy to production?', ok: 'Deploy'
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

                    node_modules/.bin/netlify deploy \
                      --dir=build \
                      --no-build \
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
        }
    }
}
