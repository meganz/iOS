
def injectEnvironments(Closure body) {
    withEnv([
        "PATH=/Applications/MEGAcmd.app/Contents/MacOS:/Applications/CMake.app/Contents/bin:$PATH:/usr/local/bin",
        "LC_ALL=en_US.UTF-8",
        "LANG=en_US.UTF-8"
    ]) {
        body.call()
    }
}

pipeline {
   agent { label 'mac-slave' }
   environment {
       CONSOLE_LOG_FILE = "consoleLog.txt"
   }
   options {
        timeout(time: 1, unit: 'HOURS') 
        gitLabConnection('GitLabConnection')
   }
   post { 
        failure {
            script {
                def comment = "Console log: ${env.GIT_BRANCH}"
                if (env.CHANGE_URL) {
                    comment = "Console log: ${env.GIT_BRANCH} ${env.CHANGE_URL}"
                }
                slackUploadFile filePath: env.CONSOLE_LOG_FILE, initialComment: comment
            } 
        }
    }
    stages {
        stage('Submodule update') {
            steps {
                gitlabCommitStatus(name: 'Submodule update') {
                    withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                    injectEnvironments({
                            sh "git submodule foreach --recursive git clean -xfd > ${env.CONSOLE_LOG_FILE}"
                            sh "git submodule sync --recursive >> ${env.CONSOLE_LOG_FILE}"
                            sh "git submodule update --init --recursive >> ${env.CONSOLE_LOG_FILE}"
                        })
                    }
                }
            }
        }

        stage('Downloading dependencies') {
            steps {
                gitlabCommitStatus(name: 'Downloading dependencies') {
                    injectEnvironments({
                        retry(3) {
                            sh "sh download_3rdparty.sh >> ${env.CONSOLE_LOG_FILE}"
                        }
                        sh "bundle install >> ${env.CONSOLE_LOG_FILE}"
                        sh "bundle exec pod repo update >> ${env.CONSOLE_LOG_FILE}"
                        sh "bundle exec pod cache clean --all --verbose >> ${env.CONSOLE_LOG_FILE}"
                        sh "bundle exec pod install --verbose >> ${env.CONSOLE_LOG_FILE}"
                    })
                }
            }
        }

        stage('Running CMake') {
            steps {
                gitlabCommitStatus(name: 'Running CMake') {
                    injectEnvironments({
                        dir("iMEGA/Vendor/Karere/src/") {
                            sh "cmake -P genDbSchema.cmake >> ${env.CONSOLE_LOG_FILE}"
                        }
                    })
                }
            }
        }

        stage('Run Unit test') {
            steps {
                gitlabCommitStatus(name: 'Run unit test') {
                    injectEnvironments({
                        sh "arch -x86_64 bundle exec fastlane tests >> ${env.CONSOLE_LOG_FILE}"
                    })
                }
            }
        }
    }
}
