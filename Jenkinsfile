pipeline {
    agent any

    triggers { githubPush() }

    options {
        disableConcurrentBuilds()
        timeout(time: 10, unit: 'MINUTES')
    }

    environment {
        DEPLOY_USER = 'demo2-jenkins'
        JAR     = 'cinema-booking-1.0.0-SNAPSHOT.jar'
        APP_DIR = '/home/demo2-jenkins/DevOps-Demo1/target'
    }

    stages {
        stage('Tests') {
    steps {
        sh 'mvn test'
    }
}

stage('Build') {
    steps {
        sh 'mvn package -DskipTests'
    }
}
        stage('Deploy to app1') {
            steps {
                sh '''
                    ssh $DEPLOY_USER@app1 "mkdir -p $APP_DIR"
                    scp target/$JAR $DEPLOY_USER@app1:$APP_DIR/
                    ssh $DEPLOY_USER@app1 "sudo -n /opt/cinema/setup_app.sh"
                    timeout 120 bash -c 'until curl -sf -o /dev/null http://app1:8080; do sleep 5; done'
                '''
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
        }
    }
}
