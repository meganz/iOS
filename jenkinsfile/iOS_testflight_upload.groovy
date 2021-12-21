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
        gitLabConnection('GitLabConnection')
    }
    environment {
        APP_STORE_CONNECT_KEY_ID = credentials('APP_STORE_CONNECT_KEY_ID')
        APP_STORE_CONNECT_ISSUER_ID = credentials('APP_STORE_CONNECT_ISSUER_ID')
        APP_STORE_CONNECT_API_KEY_B64 = credentials('APP_STORE_CONNECT_API_KEY_B64')
        MATCH_PASSWORD = credentials('MATCH_PASSWORD')
    }
    post {
        success {
            slackSend color: "good", message: "Build ${env.MEGA_VERSION_NUMBER} (${env.MEGA_BUILD_NUMBER}) uploaded successfully to Testflight"
        }
        failure {
            script {
                withCredentials([usernameColonPassword(credentialsId: 'Jenkins-Login', variable: 'CREDENTIALS')]) {
                    sh 'curl -u $CREDENTIALS ${BUILD_URL}/consoleText -o console.txt'
                    slackUploadFile filePath:"console.txt", initialComment:"Testflight build ${env.MEGA_VERSION_NUMBER} (${env.MEGA_BUILD_NUMBER}) failed"
                }
            }
        }
        cleanup {
            cleanWs()
        }
    }
    stages {
        stage('Submodule update') {
            steps {
                gitlabCommitStatus(name: 'Submodule update') {
                    withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                        injectEnvironments({
                            sh "git submodule foreach --recursive git clean -xfd"
                            sh "git submodule sync --recursive"
                            sh "git submodule update --init --recursive"
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
                            sh "sh download_3rdparty.sh"
                        }
                        sh "bundle install"
                        sh "bundle exec pod repo update"
                        sh "bundle exec pod cache clean --all --verbose"
                        sh "bundle exec pod install --verbose "
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

        stage('Set build number') {
            steps {
                gitlabCommitStatus(name: 'Set build number') {
                    injectEnvironments({
                        sh "bundle exec fastlane set_time_as_build_number"
                        sh "bundle exec fastlane fetch_version_number"
                        script {
                            env.MEGA_BUILD_NUMBER = readFile(file: './fastlane/build_number.txt')
                            env.MEGA_VERSION_NUMBER = readFile(file: './fastlane/version_number.txt')
                        }
                    })
                }
            }
        }

        stage('Create temporary keychain') {
            steps {
                gitlabCommitStatus(name: 'Create Temporary keychain') {
                    injectEnvironments({
                        sh "bundle exec fastlane create_temporary_keychain"
                    })
                }
            }
        }

        stage('Install certificate and profiles to temp_keychain') {
            steps {
                gitlabCommitStatus(name: 'Install certificate and profiles to temp_keychain') {
                    withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                        injectEnvironments({
                            sh "bundle exec fastlane install_certificate_and_profile_to_temp_keychain type:'appstore'"
                        })
                    }
                }
            }
        }

        stage('Archive') {
            steps {
                gitlabCommitStatus(name: 'Archive') {
                    injectEnvironments({
                        sh "arch -x86_64 bundle exec fastlane archive_appstore"
                    })
                }
            }
        }

        stage('Upload to Testflight') {     
            steps {
                gitlabCommitStatus(name: 'Upload to Testflight') {
                    withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                        injectEnvironments({
                            sh "bundle exec fastlane upload_to_itunesconnect"
                        })
                    }
                }
            }
        }

        stage('Upload symbols to crashlytics') {
            steps {
                gitlabCommitStatus(name: 'Upload symbols to crashlytics') {
                    injectEnvironments({
                        sh "bundle exec fastlane upload_symbols"
                    })
                }
            }
        }

        stage('Delete temporary keychain') {
            steps {
                gitlabCommitStatus(name: 'Delete temporary keychain') {
                    injectEnvironments({
                        sh "bundle exec fastlane delete_temporary_keychain"
                        sh "security default-keychain -s ~/Library/keychains/login.keychain"
                    })
                }
            }
        }
    }
}
