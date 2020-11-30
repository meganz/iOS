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
   agent any

   stages {
        stage('Submodule update') {
            steps {
                injectEnvironments({
                sh "git submodule update --init --recursive"
                })
            }
        }

        stage('Downloading dependencies') {
            steps {
                injectEnvironments({
                    retry(3) {
                        sh "sh $WORKSPACE/download_3rdparty.sh"
                    }
                    sh "bundle install"
                    sh "bundle exec pod repo update"
                    sh "bundle exec pod cache clean --all --verbose"
                    sh "bundle exec pod install --verbose"                
                })
            }
        }

        stage('Running CMake') {
            steps {
                injectEnvironments({
                    dir("iMEGA/Vendor/Karere/src/") {
                        sh "cmake -P genDbSchema.cmake"
                    }
                })
            }
        }

        stage('Generating Executable (IPA)') {
            steps {
                injectEnvironments({
                    sh "bundle exec fastlane build_using_development BUILD_NUMBER:$BUILD_NUMBER"
                })
            }
        }

        stage('Upload and Deploy') {
            parallel {
                stage('Deploying executable (IPA) to Appcenter') {
                    steps {
                        injectEnvironments({
                            retry(3) {
                                sh "bundle exec fastlane upload_to_appcenter ENV:DEV"
                            }
                        })
                    }
                }

                stage('Upload (dSYMs) to Firebase') {
                    steps {
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
   
    post {
        always { 
            callSlack(currentBuild.currentResult)
        }
    }
}
