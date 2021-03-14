
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
   agent any
   options {
        timeout(time: 1, unit: 'HOURS') 
        gitLabConnection('hl')
   }
    environment {
        APP_STORE_CONNECT_API_KEY_B64 = credentials('APP_STORE_CONNECT_API_KEY_B64')
    }
    post {
      failure {
        updateGitlabCommitStatus(name: 'Jenkins', state: 'failed')
      }
      success {
        updateGitlabCommitStatus(name: 'Jenkins', state: 'success')
      }
    }
   stages {
        stage('Submodule update') {
            steps {
                gitlabCommitStatus(name: 'Submodule update') {
                    injectEnvironments({
                        sh "git submodule foreach --recursive git clean -xfd"
                        sh "git submodule sync --recursive"
                        sh "git submodule update --init --recursive"
                    })
                }
            }
        }

        stage('Downloading dependencies') {
            steps {
                gitlabCommitStatus(name: 'Downloading dependencies') {
                    injectEnvironments({
                        retry(3) {
                            sh "sh ./download_3rdparty.sh"
                        }
                        sh "bundle install"
                        sh "bundle exec pod repo update"
                        sh "bundle exec pod cache clean --all --verbose"
                        sh "bundle exec pod install --verbose"
                    })
                }
            }
        }

        stage('Running CMake') {
            steps {
                gitlabCommitStatus(name: 'Running CMake') {
                    injectEnvironments({
                        dir("iMEGA/Vendor/Karere/src/") {
                            sh "cmake -P genDbSchema.cmake"
                        }
                    })
                }
            }
        }

        stage('Run Unit test') {
            steps {
                gitlabCommitStatus(name: 'Run Unit test') {
                    injectEnvironments({
                        sh "arch -x86_64 bundle exec fastlane tests"
                    })
                }
            }
        }
   }
}
