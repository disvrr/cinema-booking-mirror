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
         REMOTE_APP_DIR = '/opt/cinema'
STAGING_DIR = '/tmp/cinema-deploy'
    APP1_HOST = '10.0.2.209'
    APP2_HOST = '10.0.2.138'

    SSH_OPTS = '-o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10'
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
                sh '''
                mvn package -DskipTests
                test -s "target/$JAR"
                ls -lh "target/$JAR"
            '''
            }
        }
        stage('Deploy to app1') {
            steps {
            sh '''
                    set -eu

                    ssh $DEPLOY_USER@$APP1_HOST \
                        "mkdir -p $STAGING_DIR"

                    scp apps-db/setup_app.sh \
                        apps-db/cinema.service \
                        target/$JAR \
                        $DEPLOY_USER@$APP1_HOST:$STAGING_DIR/

                    ssh $DEPLOY_USER@$APP1_HOST "
                        set -eu
                        sudo -n install -o root -g root -m 755 \
                            $STAGING_DIR/setup_app.sh \
                            /opt/cinema/setup_app.sh

                        sudo -n /opt/cinema/setup_app.sh
                    "

                    timeout 120 bash -c \
                        'until curl -fsS -o /dev/null "http://$1:8080"; do sleep 5; done' \
                        _ "$APP1_HOST"
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
                    set -eu

                    ssh $DEPLOY_USER@$APP2_HOST \
                        "mkdir -p $STAGING_DIR"

                    scp apps-db/setup_app.sh \
                        apps-db/cinema.service \
                        target/$JAR \
                        $DEPLOY_USER@$APP2_HOST:$STAGING_DIR/

                    ssh $DEPLOY_USER@$APP2_HOST "
                        set -eu
                        sudo -n install -o root -g root -m 755 \
                            $STAGING_DIR/setup_app.sh \
                            /opt/cinema/setup_app.sh

                        sudo -n /opt/cinema/setup_app.sh
                    "

                    timeout 120 bash -c \
                        'until curl -fsS -o /dev/null "http://$1:8080"; do sleep 5; done' \
                        _ "$APP2_HOST"
                '''
            }
            post {
                success { script { logDeploy('app2', 'SUCCESS') } }
                failure { script { logDeploy('app2', 'FAILURE') } }
            }
        }
    }
}
