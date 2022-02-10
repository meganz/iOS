def injectEnvironments(Closure body) {
    withEnv([
        "PATH=~/.rbenv/shims:~/.rbenv/bin:/Applications/MEGAcmd.app/Contents/MacOS:/Applications/CMake.app/Contents/bin:$PATH:/usr/local/bin",
        "LC_ALL=en_US.UTF-8",
        "LANG=en_US.UTF-8"
    ]) {
        body.call()
    }
}

pipeline {
    agent { label 'mac-jenkins-slave' }
    options {
        timeout(time: 3, unit: 'HOURS') 
        gitLabConnection('GitLabConnection')
    }
    environment {
        APP_STORE_CONNECT_KEY_ID = credentials('APP_STORE_CONNECT_KEY_ID')
        APP_STORE_CONNECT_ISSUER_ID = credentials('APP_STORE_CONNECT_ISSUER_ID')
        APP_STORE_CONNECT_API_KEY_B64 = credentials('APP_STORE_CONNECT_API_KEY_B64')
        MATCH_PASSWORD = credentials('MATCH_PASSWORD')
        APP_STORE_CONNECT_API_KEY_VALUE = credentials('APP_STORE_CONNECT_API_KEY_VALUE')
        TRANSIFIX_AUTHORIZATION_TOKEN = credentials('TRANSIFIX_AUTHORIZATION_TOKEN')
    }
    post {
        success {
            script {
                def slackMessage = ":rocket: Build ${env.MEGA_VERSION_NUMBER} (${env.MEGA_BUILD_NUMBER}) uploaded successfully to Testflight"
                
                if (env.gitlabTriggerPhrase == 'upload_whats_new_to_appstoreconnect') {
                    slackMessage = ":rocket: Upload what's new to App Store Connect for version ${env.MEGA_VERSION_NUMBER} succeeded \nbranch: ${GIT_BRANCH}"
                } else if (env.gitlabTriggerPhrase == 'deliver_qa' || env.GIT_BRANCH == 'origin/develop') {
                    slackMessage = ":rocket: Build ${env.MEGA_VERSION_NUMBER} (${env.MEGA_BUILD_NUMBER}) uploaded successfully to Firebase \nbranch: ${GIT_BRANCH}"
                }
                
                slackSend color: "good", message: slackMessage
            }
        }
        failure {
            script {
                def slackMessage = ":x: Testflight build ${env.MEGA_VERSION_NUMBER} (${env.MEGA_BUILD_NUMBER}) failed \nbranch: ${GIT_BRANCH}"

                if (env.gitlabTriggerPhrase == 'upload_whats_new_to_appstoreconnect') {
                    slackMessage = ":x: Upload what's new to App Store Connect for version ${env.MEGA_VERSION_NUMBER} failed \nbranch: ${GIT_BRANCH}"
                } else if (env.gitlabTriggerPhrase == 'deliver_qa' || env.GIT_BRANCH == 'origin/develop') {
                    slackMessage = ":x: Firebase Build ${env.MEGA_VERSION_NUMBER} (${env.MEGA_BUILD_NUMBER}) failed \nbranch: ${GIT_BRANCH}"
                }

                withCredentials([usernameColonPassword(credentialsId: 'Jenkins-Login', variable: 'CREDENTIALS')]) {
                    sh 'curl -u $CREDENTIALS ${BUILD_URL}/consoleText -o console.txt'
                    slackUploadFile filePath:"console.txt", initialComment: slackMessage
                }
            }                    
        }
        cleanup {
            cleanWs()
        }
    }
    stages {
        stage('Prepare') {
            parallel {
                stage('Set build number and fetch version') {
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

                stage('Download app metadata') {
                    when {
                        anyOf {
                            environment name: 'gitlabTriggerPhrase', value: 'upload_whats_new_to_appstoreconnect' 
                            environment name: 'gitlabTriggerPhrase', value: 'deliver_appStore_with_whats_new' 
                        }
                    }
                    steps {
                        gitlabCommitStatus(name: 'Download app metadata') {
                            injectEnvironments({
                                sh 'bundle exec fastlane download_metadata'
                            })
                        }
                    }
                }
            }
        }
        
        stage('Install Dependencies') {
            when { 
                anyOf {
                    environment name: 'gitlabTriggerPhrase', value: 'deliver_appStore' 
                    environment name: 'gitlabTriggerPhrase', value: 'deliver_qa' 
                    environment name: 'gitlabTriggerPhrase', value: 'deliver_appStore_with_whats_new' 
                    environment name: 'GIT_BRANCH', value: 'origin/develop'
                }
            }
            parallel {
                stage('Submodule update and run cmake') {
                    steps {
                        gitlabCommitStatus(name: 'Submodule update and run cmake') {
                            withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                                injectEnvironments({
                                    sh "git submodule foreach --recursive git clean -xfd"
                                    sh "git submodule sync --recursive"
                                    sh "git submodule update --init --recursive"
                                    dir("iMEGA/Vendor/Karere/src/") {
                                        sh "cmake -P genDbSchema.cmake"
                                    }
                                })
                            }
                        }
                    }
                }

                stage('Update pods') {
                    steps {
                        gitlabCommitStatus(name: 'Update pods') {
                            injectEnvironments({
                                sh "bundle install"
                                sh "bundle exec pod repo update"
                                sh "bundle exec pod cache clean --all --verbose"
                                sh "bundle exec pod install --verbose"
                            })
                        }
                    }
                }

                stage('Downloading third party libraries') {
                    steps {
                        gitlabCommitStatus(name: 'Downloading third party libraries') {
                            injectEnvironments({
                                retry(3) {
                                    sh "sh download_3rdparty.sh"
                                }
                            })
                        }
                    }
                }

                stage('Install certificate and provisioning profiles in temporary keychain') {
                    steps {
                        gitlabCommitStatus(name: 'Install certificate and provisioning profiles in temporary keychain') {
                            injectEnvironments({
                                sh "bundle exec fastlane create_temporary_keychain"
                                withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                                    sh "bundle exec fastlane install_certificate_and_profile_to_temp_keychain type:'appstore' readonly:true"                                   
                                    sh "bundle exec fastlane install_certificate_and_profile_to_temp_keychain type:'adhoc' readonly:false"
                                }
                            })
                        }
                    }
                }
            }
        }

        stage('Archive appstore') {
            when { 
                anyOf {
                    environment name: 'gitlabTriggerPhrase', value: 'deliver_appStore' 
                    environment name: 'gitlabTriggerPhrase', value: 'deliver_appStore_with_whats_new' 
                }
            }
            steps {
                gitlabCommitStatus(name: 'Archive appstore') {
                    injectEnvironments({
                        sh "bundle exec fastlane archive_appstore"
                        script {
                            env.MEGA_BUILD_ARCHIVE_PATH = readFile(file: './fastlane/archive_path.txt')
                        }
                    })
                }
            }
        }

        stage('Archive adhoc') {
            when { 
                anyOf {
                    environment name: 'gitlabTriggerPhrase', value: 'deliver_qa' 
                    environment name: 'GIT_BRANCH', value: 'origin/develop'
                }
            }
            steps {
                gitlabCommitStatus(name: 'Archive adhoc') {
                    injectEnvironments({
                        sh "bundle exec fastlane archive_adhoc"
                    })
                }
            }
        }

        stage('Upload') {
            parallel {
                stage('Upload to Testflight') {    
                    when { 
                        anyOf {
                            environment name: 'gitlabTriggerPhrase', value: 'deliver_appStore' 
                            environment name: 'gitlabTriggerPhrase', value: 'deliver_appStore_with_whats_new' 
                        }
                    } 
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
                    when { 
                        anyOf {
                            environment name: 'gitlabTriggerPhrase', value: 'deliver_appStore' 
                            environment name: 'gitlabTriggerPhrase', value: 'deliver_qa'
                            environment name: 'gitlabTriggerPhrase', value: 'deliver_appStore_with_whats_new' 
                            environment name: 'GIT_BRANCH', value: 'origin/develop'
                        }
                    }
                    steps {
                        gitlabCommitStatus(name: 'Upload symbols to crashlytics') {
                            injectEnvironments({
                                sh "bundle exec fastlane upload_symbols"
                            })
                        }
                    }
                }

                stage('Upload build to Firebase') {
                    when { 
                        anyOf {
                            environment name: 'gitlabTriggerPhrase', value: 'deliver_qa'
                            environment name: 'GIT_BRANCH', value: 'origin/develop'
                        }
                    }
                    steps {
                        gitlabCommitStatus(name: 'Upload build to Firebase') {
                            injectEnvironments({
                                withCredentials([file(credentialsId: 'ios_firebase_credentials', variable: 'firebase_credentials')]) {
                                    sh "cp \$firebase_credentials service_credentials_file.json"
                                    sh "bundle exec fastlane upload_build_to_firebase"
                                } 
                            })
                        }
                    }
                }

                stage('Prepare archive zip to be uploaded to MEGA') {
                    when { 
                        anyOf {
                            environment name: 'gitlabTriggerPhrase', value: 'deliver_appStore' 
                            environment name: 'gitlabTriggerPhrase', value: 'deliver_appStore_with_whats_new' 
                        }
                    }
                    steps {
                        gitlabCommitStatus(name: 'Prepare archive zip to be uploaded to MEGA') {
                            injectEnvironments({
                                script {
                                    def fileName = "${env.MEGA_VERSION_NUMBER}-${env.MEGA_BUILD_NUMBER}.zip"
                                    def zipPath = "${WORKSPACE}/${fileName}"
                                    sh "bundle exec fastlane zip_Archive archive_path:\'${env.MEGA_BUILD_ARCHIVE_PATH}\' zip_path:${zipPath}"
                                    sh "mkdir -p ./../iOS-Archives/ && mv ${zipPath} ./../iOS-Archives/"
                                } 
                            })
                        }
                    }
                }

                stage('Update what\'s new to appstore connect') {
                    when {
                        anyOf {
                            environment name: 'gitlabTriggerPhrase', value: 'upload_whats_new_to_appstoreconnect' 
                            environment name: 'gitlabTriggerPhrase', value: 'deliver_appStore_with_whats_new' 
                        }
                    }
                    steps {
                        gitlabCommitStatus(name: 'Update what\'s new to appstore connect') {
                            injectEnvironments({
                                dir("fastlane/") {
                                    sh 'python3 UploadChangeLogs.py \"$TRANSIFIX_AUTHORIZATION_TOKEN\" $MEGA_VERSION_NUMBER'
                                }
                                sh 'bundle exec fastlane upload_metadata_to_appstore_connect'
                            })
                        }
                    }
                }
            }
        }

        stage('Delete temporary keychain') {
            when { 
                anyOf {
                    environment name: 'gitlabTriggerPhrase', value: 'deliver_appStore' 
                    environment name: 'gitlabTriggerPhrase', value: 'deliver_qa'
                    environment name: 'gitlabTriggerPhrase', value: 'deliver_appStore_with_whats_new' 
                    environment name: 'GIT_BRANCH', value: 'origin/develop'
                }
            }
            steps {
                gitlabCommitStatus(name: 'Delete temporary keychain') {
                    injectEnvironments({
                        sh "bundle exec fastlane delete_temporary_keychain"
                    })
                }
            }
        }
    }
}
