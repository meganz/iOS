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
    options {
        timeout(time: 3, unit: 'HOURS') 
        gitLabConnection('GitLabConnection')
    }
    environment {
        APP_STORE_CONNECT_KEY_ID = credentials('APP_STORE_CONNECT_KEY_ID')
        APP_STORE_CONNECT_ISSUER_ID = credentials('APP_STORE_CONNECT_ISSUER_ID')
        APP_STORE_CONNECT_API_KEY_B64 = credentials('APP_STORE_CONNECT_API_KEY_B64')
        MATCH_PASSWORD = credentials('MATCH_PASSWORD')
        CONSOLE_LOG_FILE = "consoleLog.txt"
    }
    post {
        success {
            slackSend color: "good", message: "Build ${env.MEGA_VERSION_NUMBER} (${env.MEGA_BUILD_NUMBER}) uploaded successfully to Testflight"
        }
        failure {
            slackUploadFile filePath: env.CONSOLE_LOG_FILE, initialComment: "Testflight build ${env.MEGA_VERSION_NUMBER} (${env.MEGA_BUILD_NUMBER}) failed"
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
                        runShell "bundle exec pod install --verbose "
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

        stage('Set build number') {
            steps {
                gitlabCommitStatus(name: 'Set build number') {
                    injectEnvironments({
                        runShell "bundle exec fastlane set_time_as_build_number"
                        runShell "bundle exec fastlane fetch_version_number"
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
                        runShell "bundle exec fastlane create_temporary_keychain"
                    })
                }
            }
        }

        stage('Install certificate and profiles to temp_keychain') {
            steps {
                gitlabCommitStatus(name: 'Install certificate and profiles to temp_keychain') {
                    withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                        injectEnvironments({
                            runShell "bundle exec fastlane install_certificate_and_profile_to_temp_keychain type:'appstore'"
                        })
                    }
                }
            }
        }

        stage('Archive') {
            steps {
                gitlabCommitStatus(name: 'Archive') {
                    injectEnvironments({
                        runShell "arch -x86_64 bundle exec fastlane archive_appstore"
                    })
                }
            }
        }

        stage('Upload to Testflight') {     
            steps {
                gitlabCommitStatus(name: 'Upload to Testflight') {
                    withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                        injectEnvironments({
                            runShell "bundle exec fastlane upload_to_itunesconnect"
                        })
                    }
                }
            }
        }

        stage('Upload symbols to crashlytics') {
            steps {
                gitlabCommitStatus(name: 'Upload symbols to crashlytics') {
                    injectEnvironments({
                        runShell "bundle exec fastlane upload_symbols"
                    })
                }
            }
        }

        stage('Delete temporary keychain') {
            steps {
                gitlabCommitStatus(name: 'Delete temporary keychain') {
                    injectEnvironments({
                        runShell "bundle exec fastlane delete_temporary_keychain"
                        runShell "security default-keychain -s ~/Library/keychains/login.keychain"
                    })
                }
            }
        }
    }
}
