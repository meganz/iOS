
def callSlack(String buildResult) {
    if ( buildResult == "SUCCESS" ) {
        slackSend color: "good", message: "Job: ${env.JOB_NAME} with buildnumber ${env.BUILD_NUMBER} was successful"
    }
    else if( buildResult == "FAILURE" ) { 
        slackSend color: "danger", message: "Job: ${env.JOB_NAME} with buildnumber ${env.BUILD_NUMBER} was failed"
    }
    else if( buildResult == "UNSTABLE" ) { 
        slackSend color: "warning", message: "Job: ${env.JOB_NAME} with buildnumber ${env.BUILD_NUMBER} was unstable"
    }
    else {
        slackSend color: "danger", message: "Job: ${env.JOB_NAME} with buildnumber ${env.BUILD_NUMBER} its result was unclear"    
    }
}

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
   options {
        timeout(time: 3, unit: 'HOURS') 
        gitLabConnection('iosdev')
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

        stage('Generating Executable (IPA)') {
            steps {
                gitlabCommitStatus(name: 'Generating Executable (IPA)') {
                    injectEnvironments({
                        sh "arch -x86_64 bundle exec fastlane build_release BUILD_NUMBER:$BUILD_NUMBER"
                    })
                }
            }
        }

        stage('Upload and Deploy') {
            parallel {
                stage('Deploying executable (IPA) to iTunes Connect') {
                    steps {
                        gitlabCommitStatus(name: 'Deploying executable (IPA) to iTunes Connect') {
                            injectEnvironments({
                                retry(3) {
                                sh "bundle exec fastlane upload_to_itunesconnect ENV:DEV"
                                }
                            })
                        }
                    }
                }

                stage('Upload (dSYMs) to Firebase') {
                    steps {
                        gitlabCommitStatus(name: 'Upload (dSYMs) to Firebase') {
                            injectEnvironments({
                                retry(3) {
                                    sh "bundle exec fastlane upload_symbols ENV:DEV"
                                }
                            })
                        }
                    }
                }
            }
        }
    }
}
