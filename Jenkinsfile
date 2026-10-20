def logDeploy(String server, String result) {
    sh "echo \"\$(date -u +%Y-%m-%dT%H:%M:%SZ) server=${server} build=${env.BUILD_NUMBER} result=${result}\" >> /var/log/deploy-events.log"
}
pipeline {
    agent any

    triggers { githubPush() }

    options {
        disableConcurrentBuilds()
        timeout(time: 10, unit: 'MINUTES')
    }

    environment {
        DEPLOY_USER = 'diana'
        JAR     = 'cinema-booking-1.0.0-SNAPSHOT.jar'
        APP_DIR = '/home/diana/DevOps-Demo1/target'
        APP1_HOST   = '10.0.2.209'   
        APP2_HOST   = '10.0.2.138'  
        SSH_OPTS    = '-o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10'
    }

    stages {
     stage('Tests') {
            steps {
                sh '''
                    mvn clean test \
                      -Dtest='!BookingRepositoryTest,!BookingSeatRepositoryTest,!HallRepositoryTest,!MovieImageRepositoryTest,!MovieRepositoryTest,!RoleRepositoryTest,!ScreeningRepositoryTest,!SeatRepositoryTest,!TicketTypeRepositoryTest,!UserRepositoryTest,!BookingJdbcRepositoryTest,!ReportingDaoTest'
                '''
            }
}
        stage('Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }
        stage('Deploy to app1') {
            steps {
                sh '''
                    scp $SSH_OPTS ~/cinema-booking-mirror/apps-db/setup_app.sh $DEPLOY_USER@$APP1_HOST:/tmp/setup_app.sh
                    ssh $SSH_OPTS $DEPLOY_USER@$APP1_HOST "sudo mv /tmp/setup_app.sh /opt/cinema/setup_app.sh && sudo chmod 755 /opt/cinema/setup_app.sh"
                    ssh $SSH_OPTS $DEPLOY_USER@$APP1_HOST "sudo -n /opt/cinema/setup_app.sh" 
                    timeout 120 bash -c "until curl -sf -o /dev/null http://$APP1_HOST:8080; do sleep 5; done"
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
                    scp $SSH_OPTS ~/cinema-booking-mirror/apps-db/setup_app.sh $DEPLOY_USER@$APP2_HOST:/tmp/setup_app.sh
                    ssh $SSH_OPTS $DEPLOY_USER@$APP2_HOST "sudo mv /tmp/setup_app.sh /opt/cinema/setup_app.sh && sudo chmod 755 /opt/cinema/setup_app.sh"
                    ssh $SSH_OPTS $DEPLOY_USER@$APP2_HOST "sudo -n /opt/cinema/setup_app.sh" 
                    timeout 120 bash -c "until curl -sf -o /dev/null http://$APP2_HOST:8080; do sleep 5; done"
                '''
            }
            post {
                success { script { logDeploy('app2', 'SUCCESS') } }
                failure { script { logDeploy('app2', 'FAILURE') } }
            }
        }
    }
}