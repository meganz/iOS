
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
   }
    environment {
        APP_STORE_CONNECT_API_KEY = credentials('AuthKey_J62DXF966A.p8')
    }
   stages {
      stage('Submodule update') {
         steps {
            injectEnvironments({
              sh "git submodule foreach --recursive git clean -xfd"
              sh "git submodule sync --recursive"
              sh "git submodule update --init --recursive"
            })
        }
      }

        stage('Downloading dependencies') {
            steps {
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
                    sh "arch -x86_64 bundle exec fastlane build_using_development BUILD_NUMBER:$BUILD_NUMBER"
                })
            }
        }
   }
}
