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
        SSH_KEY = '/var/lib/jenkins/.ssh/id_ed25519'

        JAR = 'cinema-booking-1.0.0-SNAPSHOT.jar'

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

                    ssh -i "$SSH_KEY" $SSH_OPTS \
                        "$DEPLOY_USER@$APP1_HOST" \
                        "mkdir -p '$STAGING_DIR'"

                    scp -i "$SSH_KEY" $SSH_OPTS \
                        apps-db/setup_app.sh \
                        apps-db/cinema.service \
                        "target/$JAR" \
                        "$DEPLOY_USER@$APP1_HOST:$STAGING_DIR/"

                    ssh -i "$SSH_KEY" $SSH_OPTS \
                        "$DEPLOY_USER@$APP1_HOST" "
                            set -eu

                            sudo -n install -d \
                                '$REMOTE_APP_DIR' \
                                /var/log/cinema

                            sudo -n install -o root -g root -m 755 \
                                '$STAGING_DIR/setup_app.sh' \
                                '$REMOTE_APP_DIR/setup_app.sh'

                            sudo -n install -o ubuntu -g ubuntu -m 644 \
                                '$STAGING_DIR/$JAR' \
                                '$REMOTE_APP_DIR/$JAR'

                            test -f '$REMOTE_APP_DIR/cinema.env'
                            id ubuntu >/dev/null
                            command -v java >/dev/null

                            cd '$STAGING_DIR'
                            sudo -n '$REMOTE_APP_DIR/setup_app.sh'
                        "

                  ssh -i "$SSH_KEY" $SSH_OPTS "$DEPLOY_USER@$APP1_HOST" \
    'timeout 120 bash -c '\''until curl -fsS --max-time 5 -o /dev/null http://127.0.0.1:8080/; do sleep 5; done'\
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

                    ssh -i "$SSH_KEY" $SSH_OPTS \
                        "$DEPLOY_USER@$APP2_HOST" \
                        "mkdir -p '$STAGING_DIR'"

                    scp -i "$SSH_KEY" $SSH_OPTS \
                        apps-db/setup_app.sh \
                        apps-db/cinema.service \
                        "target/$JAR" \
                        "$DEPLOY_USER@$APP2_HOST:$STAGING_DIR/"

                    ssh -i "$SSH_KEY" $SSH_OPTS \
                        "$DEPLOY_USER@$APP2_HOST" "
                            set -eu

                            sudo -n install -d \
                                '$REMOTE_APP_DIR' \
                                /var/log/cinema

                            sudo -n install -o root -g root -m 755 \
                                '$STAGING_DIR/setup_app.sh' \
                                '$REMOTE_APP_DIR/setup_app.sh'

                            sudo -n install -o ubuntu -g ubuntu -m 644 \
                                '$STAGING_DIR/$JAR' \
                                '$REMOTE_APP_DIR/$JAR'

                            test -f '$REMOTE_APP_DIR/cinema.env'
                            id ubuntu >/dev/null
                            command -v java >/dev/null

                            cd '$STAGING_DIR'
                            sudo -n '$REMOTE_APP_DIR/setup_app.sh'
                        "

                   ssh -i "$SSH_KEY" $SSH_OPTS "$DEPLOY_USER@$APP2_HOST" \
    'timeout 120 bash -c '\''until curl -fsS --max-time 5 -o /dev/null http://127.0.0.1:8080/; do sleep 5; done'\
                '''
            }
            post {
                success { script { logDeploy('app2', 'SUCCESS') } }
                failure { script { logDeploy('app2', 'FAILURE') } }
            }
        }
    }
}
