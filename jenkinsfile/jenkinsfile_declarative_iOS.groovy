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
        slackSend color: "danger", message: "Job: ${env.JOB_NAME} with buildnumber ${env.BUILD_NUMBER} its resulat was unclear"	
    }
}

def clearnProject() {
    sh "git clean -f"
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
      stage('checkout submodule') {
         steps {
            injectEnvironments({
              sh "git submodule update --init --recursive"
            })
        }
      }

        stage('download depedency') {
            steps {
                injectEnvironments({
                    sh "git submodule update --init --recursive"
                    sh "mega-get https://mega.nz/#!CjwkmYTB!gIJrmV5cR3Nk4ZTYTY-89aVYEioD-RU_vAOMPZsfcdA $WORKSPACE/iMEGA/Vendor/SDK/bindings/ios/3rdparty/"
                })
            }
        }


        stage('unzip depedency') {
            steps {
                injectEnvironments({
                    sh "unzip -o $WORKSPACE/iMEGA/Vendor/SDK/bindings/ios/3rdparty/wrtc.zip -d $WORKSPACE/iMEGA/Vendor/SDK/bindings/ios/3rdparty/"
                })
            }
        }

        stage('Initial Build') {
            steps {
                injectEnvironments({
                    dir("iMEGA/Vendor/Karere/src/") {
                        sh "cmake -P genDbSchema.cmake"
                    }
                })
            }
        }

        stage('build ipa') {
            steps {
                injectEnvironments({
                    sh "fastlane build BUILD_NUMBER:$BUILD_NUMBER appcenter_api_token:$appcenter_api_token"
                })
            }
        }

        stage('deploy to appcenter') {
            steps {
                injectEnvironments({
                    retry(3) {
                        sh "fastlane upload ENV:DEV"
                    }
                })
            }
        }
   }

    post {
        always { 
            callSlack(currentBuild.currentResult)
        }
    }
}