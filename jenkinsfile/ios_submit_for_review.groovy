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
                if (hasGitLabMergeRequest()) {
                    def mr_number = env.gitlabMergeRequestIid

                    withCredentials([usernameColonPassword(credentialsId: 'Jenkins-Login', variable: 'CREDENTIALS')]) {
                        sh 'curl -u $CREDENTIALS ${BUILD_URL}/consoleText -o console.txt'
                    }

                    withCredentials([usernamePassword(credentialsId: 'Gitlab-Access-Token', usernameVariable: 'USERNAME', passwordVariable: 'TOKEN')]) {
                        final String logsResponse = sh(script: 'curl -s --request POST --header PRIVATE-TOKEN:$TOKEN --form file=@console.txt https://code.developers.mega.co.nz/api/v4/projects/193/uploads', returnStdout: true).trim()
                        def logsJSON = new groovy.json.JsonSlurperClassic().parseText(logsResponse)
                        env.MARKDOWN_LINK = ":x: Failed to submit version ${env.MEGA_VERSION_NUMBER} to the App Store. <br />Build Log: ${logsJSON.markdown}"
                        env.MERGE_REQUEST_URL = "https://code.developers.mega.co.nz/api/v4/projects/193/merge_requests/${mr_number}/notes"
                        sh 'curl --request POST --header PRIVATE-TOKEN:$TOKEN --form body=\"${MARKDOWN_LINK}\" ${MERGE_REQUEST_URL}'
                    }   
                }
            }
        }
        success {
            script {
                if (hasGitLabMergeRequest()) {
                    def mr_number = env.gitlabMergeRequestIid
                    env.MEGA_BUILD_NUMBER = readFile(file: './fastlane/build_number.txt')

                    withCredentials([usernamePassword(credentialsId: 'Gitlab-Access-Token', usernameVariable: 'USERNAME', passwordVariable: 'TOKEN')]) {
                        env.MARKDOWN_LINK = ":rocket: ${env.MEGA_VERSION_NUMBER} (${env.MEGA_BUILD_NUMBER}) has been submitted to App Store for review."
                        env.MERGE_REQUEST_URL = "https://code.developers.mega.co.nz/api/v4/projects/193/merge_requests/${mr_number}/notes"
                        sh 'curl --request POST --header PRIVATE-TOKEN:$TOKEN --form body=\"${MARKDOWN_LINK}\" ${MERGE_REQUEST_URL}'
                    }
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
                stage('Get version number') {
                    steps {
                        script {
                            injectEnvironments {
                                sh "bundle exec fastlane fetch_version_number"
                                env.MEGA_VERSION_NUMBER = readFile(file: './fastlane/version_number.txt')
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
        
        stage('Update what\'s new to appstore connect and Submit app for review') {
            steps {
                script {
                    injectEnvironments {
                        dir("scripts/") {
                            sh 'python3 download_change_logs_from_transifex.py \"$TRANSIFIX_AUTHORIZATION_TOKEN\" $MEGA_VERSION_NUMBER'
                        }

                        def used_phrase = env.gitlabTriggerPhrase
                        def phased_release = used_phrase.contains("submit_appstore_auto_phased_release")

                        if (!used_phrase.contains("build:")) {
                            error "Submit command must contain explicit build number"
                        }

                        def buildNumber = used_phrase.replaceAll(/.*build:(\d+).*/, '$1')
                        sh "bundle exec fastlane submit_review phased_release:${phased_release} build_number:${buildNumber}"
                    }
                }
            }
        }
    }
}

/**
 * Check if this build is triggered by a GitLab Merge Request.
 * @return true if this build is triggerd by a GitLab MR. False if this build is triggerd
 * by a plain git push.
 */
private boolean hasGitLabMergeRequest() {
    return env.gitlabMergeRequestIid != null && !env.gitlabMergeRequestIid.isEmpty()
}