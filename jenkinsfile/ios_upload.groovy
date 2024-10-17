def injectEnvironments(Closure body) {
    withEnv([
        "PATH=/var/lib/jenkins/.rbenv/shims:/var/lib/jenkins/.rbenv/bin:/Applications/MEGAcmd.app/Contents/MacOS:/Applications/CMake.app/Contents/bin:$PATH:/usr/local/bin",
        "LC_ALL=en_US.UTF-8",
        "LANG=en_US.UTF-8"
    ]) {
        body.call()
    }
}

pipeline {
    agent { label 'mac-jenkins-slave-ios' }
    options {
        timeout(time: 3, unit: 'HOURS') 
        gitLabConnection('GitLabConnection')
        ansiColor('xterm')
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
                def message = ":rocket: Build ${env.MEGA_VERSION_NUMBER} (${env.MEGA_BUILD_NUMBER}) uploaded successfully to Testflight"

                if (env.gitlabTriggerPhrase == 'upload_app_description_to_appstoreconnect') {
                    message = ":rocket: Upload app description to App Store Connect for version ${env.MEGA_VERSION_NUMBER} succeeded"
                } else if (env.gitlabTriggerPhrase == 'upload_whats_new_to_appstoreconnect') {
                    message = ":rocket: Upload what's new to App Store Connect for version ${env.MEGA_VERSION_NUMBER} succeeded"
                } else if (env.gitlabTriggerPhrase == 'deliver_qa' || env.gitlabTriggerPhrase == 'deliver_qa_include_new_devices' || env.GIT_BRANCH == 'origin/develop') {
                    message = ":rocket: Build ${env.MEGA_VERSION_NUMBER} (${env.MEGA_BUILD_NUMBER}) uploaded successfully to Firebase"
                } else if (env.gitlabTriggerPhrase == 'verify_translations') {
                    message = ":white_check_mark: No missing translation keys."
                }

                if (hasGitLabMergeRequest()) {
                    def mrNumber = env.gitlabMergeRequestIid

                    withCredentials([usernamePassword(credentialsId: 'Gitlab-Access-Token', usernameVariable: 'USERNAME', passwordVariable: 'TOKEN')]) {
                        env.MARKDOWN_LINK = message
                        env.MERGE_REQUEST_URL = "https://code.developers.mega.co.nz/api/v4/projects/193/merge_requests/${mrNumber}/notes"
                        sh 'curl --request POST --header PRIVATE-TOKEN:$TOKEN --form body=\"${MARKDOWN_LINK}\" ${MERGE_REQUEST_URL}'
                    }
                }

                slackSend color: "good", message: "${message} \nbranch: ${GIT_BRANCH}"
            }
        }
        failure {
            script {
                def message = ":x: Testflight build ${env.MEGA_VERSION_NUMBER} (${env.MEGA_BUILD_NUMBER}) failed"

                if (env.gitlabTriggerPhrase == 'upload_app_description_to_appstoreconnect') {
                    message = ":x: Upload app description to App Store Connect for version ${env.MEGA_VERSION_NUMBER} failed"
                } else if (env.gitlabTriggerPhrase == 'upload_whats_new_to_appstoreconnect') {
                    message = ":x: Upload what's new to App Store Connect for version ${env.MEGA_VERSION_NUMBER} failed"
                } else if (env.gitlabTriggerPhrase == 'deliver_qa' || env.gitlabTriggerPhrase == 'deliver_qa_include_new_devices' || env.GIT_BRANCH == 'origin/develop') {
                    message = ":x: Firebase Build ${env.MEGA_VERSION_NUMBER} (${env.MEGA_BUILD_NUMBER}) failed"
                } else if (env.gitlabTriggerPhrase == 'verify_translations') {
                    message = ":x: Missing translation keys."
                }

                if (hasGitLabMergeRequest()) {
                    def mrNumber = env.gitlabMergeRequestIid

                    withCredentials([usernameColonPassword(credentialsId: 'Jenkins-Login', variable: 'CREDENTIALS')]) {
                        sh 'curl -u $CREDENTIALS ${BUILD_URL}/consoleText -o console.txt'
                    }

                    withCredentials([usernamePassword(credentialsId: 'Gitlab-Access-Token', usernameVariable: 'USERNAME', passwordVariable: 'TOKEN')]) {
                        final String response = sh(script: 'curl -s --request POST --header PRIVATE-TOKEN:$TOKEN --form file=@console.txt https://code.developers.mega.co.nz/api/v4/projects/193/uploads', returnStdout: true).trim()
                        def json = new groovy.json.JsonSlurperClassic().parseText(response)
                        env.MARKDOWN_LINK = "${message} <br />Build Log: ${json.markdown}"
                        env.MERGE_REQUEST_URL = "https://code.developers.mega.co.nz/api/v4/projects/193/merge_requests/${mrNumber}/notes"
                        sh 'curl --request POST --header PRIVATE-TOKEN:$TOKEN --form body=\"${MARKDOWN_LINK}\" ${MERGE_REQUEST_URL}'
                    }
                }

                withCredentials([usernameColonPassword(credentialsId: 'Jenkins-Login', variable: 'CREDENTIALS')]) {
                    sh 'curl -u $CREDENTIALS ${BUILD_URL}/consoleText -o console.txt'
                    slackUploadFile filePath:"console.txt", initialComment: "${message} \nbranch: ${GIT_BRANCH}"
                }
            }                    
        }
        cleanup {
            cleanWs()
        }
    }
    stages {
        stage('Bundle install') {
            steps {
                gitlabCommitStatus(name: 'Bundle install') {
                    injectEnvironments({
                        sh "bundle install"
                    })
                }
            }
        }

        stage('Prepare') {
            parallel {
                stage('Set build number and fetch version') {
                    when {
                        not {
                            environment name: 'gitlabTriggerPhrase', value: 'verify_translations' 
                        }
                    }
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

                stage('Check translation') {
                    when {
                        anyOf {
                            environment name: 'gitlabTriggerPhrase', value: 'verify_translations' 
                        }
                    }
                    steps {
                        gitlabCommitStatus(name: 'Check translations') {
                            injectEnvironments({
                                dir("scripts/") {
                                    sh 'python3 check_translations.py'
                                }
                            })
                        }
                    }
                }

                stage('Download app metadata') {
                    when {
                        anyOf {
                            environment name: 'gitlabTriggerPhrase', value: 'upload_whats_new_to_appstoreconnect' 
                            environment name: 'gitlabTriggerPhrase', value: 'upload_app_description_to_appstoreconnect'
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

                stage('Download device ids from firebase and upload it to developer portal') {
                    when { 
                        anyOf {
                            environment name: 'gitlabTriggerPhrase', value: 'deliver_qa_include_new_devices' 
                        }
                    }
                    steps {
                        gitlabCommitStatus(name: 'Download device ids from firebase and upload it to developer portal') {
                            injectEnvironments({
                                withCredentials([file(credentialsId: 'ios_firebase_credentials', variable: 'firebase_credentials')]) {
                                    sh "cp \$firebase_credentials service_credentials_file.json"
                                    sh "bundle exec fastlane download_device_ids_from_firebase"
                                    sh "bundle exec fastlane upload_device_ids_to_developer_portal"
                                    sh "rm service_credentials_file.json"
                                } 
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
                    environment name: 'gitlabTriggerPhrase', value: 'deliver_qa_include_new_devices'
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
                                    dir("Modules/DataSource/MEGAChatSDK/Sources/MEGAChatSDK/src/") {
                                        sh "cmake -P genDbSchema.cmake"
                                    }
                                })
                            }
                        }
                    }
                }

                stage('Downloading third party libraries') {
                    steps {
                        gitlabCommitStatus(name: 'Downloading third party libraries') {
                            injectEnvironments({
                                sh "bundle exec fastlane configure_sdk_and_chat_library use_cache:true"
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
                                    script {
                                        def readonly = "true"
                                        if (env.gitlabTriggerPhrase == 'deliver_qa_include_new_devices') {
                                            readonly = "false"
                                        }

                                        sh "bundle exec fastlane install_certificate_and_profile_to_temp_keychain type:'development' readonly:${readonly}"
                                        sh "bundle exec fastlane install_certificate_and_profile_to_temp_keychain type:'adhoc' readonly:${readonly}"
                                    }                                   
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
                }
            }
            steps {
                gitlabCommitStatus(name: 'Archive appstore') {
                    withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                        injectEnvironments({
                            sh "bundle exec fastlane archive_appstore"
                            script {
                                env.MEGA_BUILD_ARCHIVE_PATH = readFile(file: './fastlane/archive_path.txt')
                            }
                        })
                    }
                }
            }
        }

        stage('Archive adhoc') {
            when { 
                anyOf {
                    environment name: 'gitlabTriggerPhrase', value: 'deliver_qa' 
                    environment name: 'gitlabTriggerPhrase', value: 'deliver_qa_include_new_devices'
                    environment name: 'GIT_BRANCH', value: 'origin/develop'
                }
            }
            steps {
                gitlabCommitStatus(name: 'Archive adhoc') {
                    withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                        injectEnvironments({
                            sh "bundle exec fastlane archive_adhoc"
                        })
                    }
                }
            }
        }

        stage('Upload') {
            parallel {
                stage('Upload to Testflight') {    
                    when { 
                        anyOf {
                            environment name: 'gitlabTriggerPhrase', value: 'deliver_appStore'
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
                            environment name: 'gitlabTriggerPhrase', value: 'deliver_qa_include_new_devices'
                            environment name: 'GIT_BRANCH', value: 'origin/develop'
                        }
                    }
                    steps {
                        script {
                            if (env.gitlabTriggerPhrase == 'deliver_appStore') {
                                gitlabCommitStatus(name: 'Upload appstore symbols to crashlytics') {
                                    injectEnvironments({
                                        sh "bundle exec fastlane upload_symbols configuration:Release"
                                    })
                                }
                            } else {
                                gitlabCommitStatus(name: 'Upload QA symbols to crashlytics') {
                                    injectEnvironments({
                                        sh "bundle exec fastlane upload_symbols configuration:QA"
                                    })
                                }
                            }
                        }
                    }
                }

                stage('Upload build to Firebase') {
                    when { 
                        anyOf {
                            environment name: 'gitlabTriggerPhrase', value: 'deliver_qa'
                            environment name: 'gitlabTriggerPhrase', value: 'deliver_qa_include_new_devices'
                            environment name: 'GIT_BRANCH', value: 'origin/develop'
                        }
                    }
                    steps {
                        gitlabCommitStatus(name: 'Upload build to Firebase') {
                            injectEnvironments({
                                withCredentials([file(credentialsId: 'ios_firebase_credentials', variable: 'firebase_credentials')]) {
                                    sh "cp \$firebase_credentials service_credentials_file.json"
                                    sh "bundle exec fastlane upload_build_to_firebase configuration:QA"
                                } 
                            })
                        }
                    }
                }

                stage('Prepare archive zip to be uploaded to MEGA') {
                    when { 
                        anyOf {
                            environment name: 'gitlabTriggerPhrase', value: 'deliver_appStore'
                        }
                    }
                    steps {
                        gitlabCommitStatus(name: 'Prepare archive zip to be uploaded to MEGA') {
                            injectEnvironments({
                                script {
                                    withCredentials([string(credentialsId: 'ios-mega-artifactory-upload', variable: 'ARTIFACTORY_TOKEN')]) {
                                        def fileName = "${env.MEGA_VERSION_NUMBER}-${env.MEGA_BUILD_NUMBER}.zip"
                                        env.zipPath = "${WORKSPACE}/${fileName}"
                                        env.targetPath = "https://artifactory.developers.mega.co.nz/artifactory/ios-mega/${fileName}"
                                        sh "bundle exec fastlane zip_Archive archive_path:\'${env.MEGA_BUILD_ARCHIVE_PATH}\' zip_path:${env.zipPath}"
                                        sh 'curl -H\"Authorization: Bearer $ARTIFACTORY_TOKEN\" -T ${zipPath} \"${targetPath}\"'
                                        sh 'rm ${zipPath}'
                                    }
                                } 
                            })
                        }
                    }
                }

                stage('Update what\'s new to appstore connect') {
                    when {
                        anyOf {
                            environment name: 'gitlabTriggerPhrase', value: 'upload_whats_new_to_appstoreconnect'
                        }
                    }
                    steps {
                        gitlabCommitStatus(name: 'Update what\'s new to appstore connect') {
                            injectEnvironments({
                                dir("scripts/") {
                                    sh 'python3 download_change_logs_from_transifex.py \"$TRANSIFIX_AUTHORIZATION_TOKEN\" $MEGA_VERSION_NUMBER'
                                }
                                sh 'bundle exec fastlane upload_metadata_to_appstore_connect'
                            })
                        }
                    }
                }

                stage('Update app description to appstore connect') {
                    when {
                        anyOf {
                            environment name: 'gitlabTriggerPhrase', value: 'upload_app_description_to_appstoreconnect'
                        }
                    }
                    steps {
                        gitlabCommitStatus(name: 'Update app description to appstore connect') {
                            injectEnvironments({
                                dir("scripts/AppDescriptionUpdater/") {
                                    sh 'swift run AppDescriptionUpdater \"$TRANSIFIX_AUTHORIZATION_TOKEN\"'
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
                    environment name: 'gitlabTriggerPhrase', value: 'deliver_qa_include_new_devices'
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

/**
 * Check if this build is triggered by a GitLab Merge Request.
 * @return true if this build is triggerd by a GitLab MR. False if this build is triggerd
 * by a plain git push.
 */
private boolean hasGitLabMergeRequest() {
    return env.gitlabMergeRequestIid != null && !env.gitlabMergeRequestIid.isEmpty()
}

