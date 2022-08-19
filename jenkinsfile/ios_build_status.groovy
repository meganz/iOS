
def injectEnvironments(Closure body) {
    withEnv([
        "PATH=~/.rbenv/shims:~/.rbenv/bin:/Applications/MEGAcmd.app/Contents/MacOS:/Applications/CMake.app/Contents/bin:$PATH:/usr/local/bin",
        "LC_ALL=en_US.UTF-8",
        "LANG=en_US.UTF-8"
    ]) {
        body.call()
    }
}

pipeline {
    agent { label 'mac-jenkins-slave-temp' }
    options {
        timeout(time: 1, unit: 'HOURS') 
        gitLabConnection('GitLabConnection')
        gitlabCommitStatus(name: 'Jenkins')
    }
    post { 
        failure {
            script {
                if (env.BRANCH_NAME.startsWith('MR-')) {
                    def mrNumber = env.BRANCH_NAME.replace('MR-', '')

                    withCredentials([usernameColonPassword(credentialsId: 'Jenkins-Login', variable: 'CREDENTIALS')]) {
                        sh 'curl -u $CREDENTIALS ${BUILD_URL}/consoleText -o console.txt'
                    }

                    withCredentials([usernamePassword(credentialsId: 'Gitlab-Access-Token', usernameVariable: 'USERNAME', passwordVariable: 'TOKEN')]) {
                        final String logsResponse = sh(script: 'curl -s --request POST --header PRIVATE-TOKEN:$TOKEN --form file=@console.txt https://code.developers.mega.co.nz/api/v4/projects/193/uploads', returnStdout: true).trim()
                        def logsJSON = new groovy.json.JsonSlurperClassic().parseText(logsResponse)
                        final String unitTestsHTMLOutputResponse = sh(script: 'curl -s --request POST --header PRIVATE-TOKEN:$TOKEN --form file=@report.html https://code.developers.mega.co.nz/api/v4/projects/193/uploads', returnStdout: true).trim()
                        def unitTestsHTMLJSON = new groovy.json.JsonSlurperClassic().parseText(unitTestsHTMLOutputResponse)
                        env.MARKDOWN_LINK = ":x: Build status check Failed <br />Build Log: ${logsJSON.markdown} <br />Unit Tests Report: ${unitTestsHTMLJSON.markdown}"
                        env.MERGE_REQUEST_URL = "https://code.developers.mega.co.nz/api/v4/projects/193/merge_requests/${mrNumber}/notes"
                        sh 'curl --request POST --header PRIVATE-TOKEN:$TOKEN --form body=\"${MARKDOWN_LINK}\" ${MERGE_REQUEST_URL}'
                    }
                } else {
                    withCredentials([usernameColonPassword(credentialsId: 'Jenkins-Login', variable: 'CREDENTIALS')]) {
                        def comment = ":x: Build failed for branch: ${env.GIT_BRANCH}"
                        if (env.CHANGE_URL) {
                            comment = ":x: Build failed for branch: ${env.GIT_BRANCH} \nMR Link:${env.CHANGE_URL}"
                        }
                        slackSend color: "danger", message: comment
                        sh 'curl -u $CREDENTIALS ${BUILD_URL}/consoleText -o console.txt'
                        slackUploadFile filePath:"console.txt", initialComment:"iOS Build Log"
                    }
                }
            }
            
            updateGitlabCommitStatus name: 'Jenkins', state: 'failed'
        }
        success {
            script {
                if (env.BRANCH_NAME.startsWith('MR-')) {
                    def mrNumber = env.BRANCH_NAME.replace('MR-', '')

                    withCredentials([usernamePassword(credentialsId: 'Gitlab-Access-Token', usernameVariable: 'USERNAME', passwordVariable: 'TOKEN')]) {
                        final String unitTestsHTMLOutputResponse = sh(script: 'curl -s --request POST --header PRIVATE-TOKEN:$TOKEN --form file=@report.html https://code.developers.mega.co.nz/api/v4/projects/193/uploads', returnStdout: true).trim()
                        def unitTestsHTMLJSON = new groovy.json.JsonSlurperClassic().parseText(unitTestsHTMLOutputResponse)
                        env.MARKDOWN_LINK = ":white_check_mark: Build status check succeeded <br />Unit Tests Report: ${unitTestsHTMLJSON.markdown}"
                        env.MERGE_REQUEST_URL = "https://code.developers.mega.co.nz/api/v4/projects/193/merge_requests/${mrNumber}/notes"
                        sh 'curl --request POST --header PRIVATE-TOKEN:$TOKEN --form body=\"${MARKDOWN_LINK}\" ${MERGE_REQUEST_URL}'
                    }
                }
            }

            updateGitlabCommitStatus name: 'Jenkins', state: 'success'
        }
        cleanup {
            cleanWs()
        }
    }
    stages {
        stage('Installing dependencies') {
            parallel {
                stage('Submodule update and run cmake') {
                    steps {
                        gitlabCommitStatus(name: 'Submodule update and run cmake') {
                            withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                                injectEnvironments({
                                    sh "git submodule foreach --recursive git clean -xfd"
                                    sh "git submodule sync --recursive"
                                    sh "git submodule update --init --recursive"
                                    dir("iMEGA/Vendor/Karere/src/") {
                                        sh "cmake -P genDbSchema.cmake"
                                    }
                                })
                            }
                        }
                    }
                }

                stage('Downloading third party libraries') {
                    steps {
                        gitlabCommitStatus(name: 'Downloading third party libraries') {
                            injectEnvironments({
                                retry(3) {
                                    sh "sh download_3rdparty.sh"
                                }
                            })
                        }
                    }
                }
            }
        }

        stage('Run Unit test') {
            steps {
                gitlabCommitStatus(name: 'Run unit test') {
                    injectEnvironments({
                        sh "arch -x86_64 bundle exec fastlane tests"
                    })
                }
            }
        }
    }
}
