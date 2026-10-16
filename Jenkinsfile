def logDeploy(String host, String result) {
    sh "echo \"\$(date -u +%Y-%m-%dT%H:%M:%SZ) host=${host} build=${env.BUILD_NUMBER} result=${result}\" >> /var/log/deploy-events.log"
}
pipeline {
    agent any

    triggers { githubPush() }

    options {
        disableConcurrentBuilds()
        timeout(time: 10, unit: 'MINUTES')
    }

    environment {
        DEPLOY_USER = 'deploy'
        JAR     = 'cinema-booking-1.0.0-SNAPSHOT.jar'
        APP_DIR = '/home/deploy/DevOps-Demo1/target'
    }

    stages {
        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }
stage('Deploy in parallel') {
            steps {
                script {
                    env.DEPLOYMENT_STARTED = 'true'
                }
            }

            parallel {
        stage('Deploy to app1') {
            steps {
                sh '''
                    ssh $DEPLOY_USER@app1 "mkdir -p $APP_DIR"
                    scp target/$JAR $DEPLOY_USER@app1:$APP_DIR/
                    ssh $DEPLOY_USER@app1 "sudo -n /opt/cinema/setup_app.sh"
                    timeout 120 bash -c 'until curl -sf -o /dev/null http://app1:8080; do sleep 5; done'
                '''
            }
             post {
        success { script { logDeploy('app1', 'SUCCESS') } }
        failure { script { logDeploy('app1', 'FAILURE') } }
    }
        }

        stage('Deploy to app2') {
            steps {
                sh '''
                    ssh $DEPLOY_USER@app2 "mkdir -p $APP_DIR"
                    scp target/$JAR $DEPLOY_USER@app2:$APP_DIR/
                    ssh $DEPLOY_USER@app2 "sudo -n /opt/cinema/setup_app.sh"
                    timeout 120 bash -c 'until curl -sf -o /dev/null http://app2:8080; do sleep 5; done'
                '''
            }
             post {
        success { script { logDeploy('app2', 'SUCCESS') } }
        failure { script { logDeploy('app2', 'FAILURE') } }
    }
        }
    }
}
}
}



