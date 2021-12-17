
def injectEnvironments(Closure body) {
    withEnv([
        "PATH=/Applications/MEGAcmd.app/Contents/MacOS:/Applications/CMake.app/Contents/bin:$PATH:/usr/local/bin",
        "LC_ALL=en_US.UTF-8",
        "LANG=en_US.UTF-8"
    ]) {
        body.call()
    }
}

def runShell(String cmd) {
    sh "${cmd} >> ${CONSOLE_LOG_FILE} 2>&1"
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
                            runShell "git submodule foreach --recursive git clean -xfd"
                            runShell "git submodule sync --recursive"
                            runShell "git submodule update --init --recursive"
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
                            runShell "sh download_3rdparty.sh"
                        }
                        runShell "bundle install"
                        runShell "bundle exec pod repo update"
                        runShell "bundle exec pod cache clean --all --verbose"
                        runShell "bundle exec pod install --verbose"
                    })
                }
            }
        }

        stage('Running CMake') {
            steps {
                gitlabCommitStatus(name: 'Running CMake') {
                    injectEnvironments({
                        dir("iMEGA/Vendor/Karere/src/") {
                            runShell "cmake -P genDbSchema.cmake"
                        }
                    })
                }
            }
        }

        stage('Run Unit test') {
            steps {
                gitlabCommitStatus(name: 'Run unit test') {
                    injectEnvironments({
                        runShell "arch -x86_64 bundle exec fastlane tests"
                    })
                }
            }
        }
    }
}
