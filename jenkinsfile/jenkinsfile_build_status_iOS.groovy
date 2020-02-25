
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
                    sh "mega-get https://mega.nz/#!BUtgzAQL!rf6stzMWq-RJ9u9-l8jeYZ0kSd07fwSDSG3P3Uj9Mx0 $WORKSPACE/iMEGA/Vendor/SDK/bindings/ios/3rdparty/"
                })
            }
        }


        stage('Unzipping dependencies and moving files/folders to appropriate path') {
            steps {
                injectEnvironments({
                    sh "unzip -o $WORKSPACE/iMEGA/Vendor/SDK/bindings/ios/3rdparty/3rdparty.zip -d $WORKSPACE/iMEGA/Vendor/SDK/bindings/ios/3rdparty/"
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
                    sh "fastlane build_using_development BUILD_NUMBER:$BUILD_NUMBER"
                })
            }
        }
   }
   
    post {
        cleanup{
            deleteDir()
        }
    }
}
