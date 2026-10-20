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
         REMOTE_APP_DIR = '/opt/cinema'

    APP1_HOST = '10.0.2.209'
    APP2_HOST = '10.0.2.138'

    SSH_OPTS = '-o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10'
    }

    stages {
         stage('Checkout') {
        steps {
            checkout scm

            sh '''
                echo "Current commit:"
                git rev-parse --short HEAD

                test -f apps-db/setup_app.sh
                test -f apps-db/cinema.service
            '''
        }
    }
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

                scp $SSH_OPTS \
                    "target/$JAR" \
                    "$DEPLOY_USER@$APP1_HOST:/tmp/$JAR"

                ssh $SSH_OPTS "$DEPLOY_USER@$APP1_HOST" "
                    sudo -n /usr/bin/install \
                        -o ubuntu -g ubuntu -m 0644 \
                        /tmp/$JAR \
                        $REMOTE_APP_DIR/$JAR

                    rm -f /tmp/$JAR

                    sudo -n /usr/bin/systemctl restart cinema
                "
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

                scp $SSH_OPTS \
                    "target/$JAR" \
                    "$DEPLOY_USER@$APP2_HOST:/tmp/$JAR"

                ssh $SSH_OPTS "$DEPLOY_USER@$APP2_HOST" "
                    sudo -n /usr/bin/install \
                        -o ubuntu -g ubuntu -m 0644 \
                        /tmp/$JAR \
                        $REMOTE_APP_DIR/$JAR

                    rm -f /tmp/$JAR

                    sudo -n /usr/bin/systemctl restart cinema
                "
            '''
            }
            post {
                success { script { logDeploy('app2', 'SUCCESS') } }
                failure { script { logDeploy('app2', 'FAILURE') } }
            }
        }
    }
}
