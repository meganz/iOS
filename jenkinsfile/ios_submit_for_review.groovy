def injectEnvironments(Closure body) {
    withEnv([
        "PATH=/var/lib/jenkins/.rbenv/shims:/var/lib/jenkins/.rbenv/bin:/Applications/MEGAcmd.app/Contents/MacOS:/Applications/CMake.app/Contents/bin:$PATH:/usr/local/bin",
        "LC_ALL=en_US.UTF-8",
        "LANG=en_US.UTF-8"
    ]) {
        body.call()
    }
}

pipeline {
    agent { label 'mac-jenkins-slave-ios' }
    options {
        timeout(time: 1, unit: 'HOURS') 
        gitLabConnection('GitLabConnection')
        ansiColor('xterm')
    }
    environment {
        APP_STORE_CONNECT_KEY_ID = credentials('APP_STORE_CONNECT_KEY_ID')
        APP_STORE_CONNECT_ISSUER_ID = credentials('APP_STORE_CONNECT_ISSUER_ID')
        APP_STORE_CONNECT_API_KEY_B64 = credentials('APP_STORE_CONNECT_API_KEY_B64')
        APP_STORE_CONNECT_API_KEY_VALUE = credentials('APP_STORE_CONNECT_API_KEY_VALUE')
        TRANSIFIX_AUTHORIZATION_TOKEN = credentials('TRANSIFIX_AUTHORIZATION_TOKEN')
    }
    post { 
        failure {
            script {
                withCredentials([usernameColonPassword(credentialsId: 'Jenkins-Login', variable: 'CREDENTIALS')]) {
                    sh 'curl -u $CREDENTIALS ${BUILD_URL}/consoleText -o console.txt'
                }

                withCredentials([usernamePassword(credentialsId: 'Gitlab-Access-Token', usernameVariable: 'USERNAME', passwordVariable: 'TOKEN')]) {
                    final String logsResponse = sh(script: 'curl -s --request POST --header PRIVATE-TOKEN:$TOKEN --form file=@console.txt https://code.developers.mega.co.nz/api/v4/projects/193/uploads', returnStdout: true).trim()
                    def logsJSON = new groovy.json.JsonSlurperClassic().parseText(logsResponse)
                    env.MARKDOWN_LINK = ":x: Failed to submit version ${params.VERSION_NUMBER} to the App Store. <br />Build Log: ${logsJSON.markdown}"
                    env.MERGE_REQUEST_URL = "https://code.developers.mega.co.nz/api/v4/projects/193/merge_requests/${params.MR_NUMBER}/notes"
                    sh 'curl --request POST --header PRIVATE-TOKEN:$TOKEN --form body=\"${MARKDOWN_LINK}\" ${MERGE_REQUEST_URL}'
                } 
            }
        }
        success {
            script {
                withCredentials([usernamePassword(credentialsId: 'Gitlab-Access-Token', usernameVariable: 'USERNAME', passwordVariable: 'TOKEN')]) {
                    env.MARKDOWN_LINK = ":rocket: ${params.VERSION_NUMBER} (${params.BUILD_NUMBER}) has been submitted to App Store for review."
                    env.MERGE_REQUEST_URL = "https://code.developers.mega.co.nz/api/v4/projects/193/merge_requests/${params.MR_NUMBER}/notes"
                    sh 'curl --request POST --header PRIVATE-TOKEN:$TOKEN --form body=\"${MARKDOWN_LINK}\" ${MERGE_REQUEST_URL}'
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
    stages {
        stage('Setup') {
            parallel {
                stage('Bundle install') {
                    steps {
                        script {
                            injectEnvironments {
                                sh 'bundle install'
                            }
                        }
                    }
                }
                stage('Download app metadata') {
                    steps {
                        script {
                            injectEnvironments {
                                sh 'bundle exec fastlane download_metadata' 
                            }
                        }
                    }
                }
            }
        } 
        
        stage('Update what\'s new and app description to appstore connect and Submit app for review') {
            steps {
                script {
                    injectEnvironments {
                        dir("scripts/AppMetadataUpdater/") {
                            env.VERSION_NUMBER = params.VERSION_NUMBER
                            sh 'swift run AppMetadataUpdater --update-description --update-release-notes -v $VERSION_NUMBER \"$TRANSIFIX_AUTHORIZATION_TOKEN\"'
                        }

                        sh "bundle exec fastlane submit_review phased_release:${params.PHASED_RELEASE} version_number:${params.VERSION_NUMBER} build_number:${params.BUILD_NUMBER}"
                    }
                }
            }
        }
    }
}