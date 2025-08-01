@Library(['jenkins-android-shared-lib', 'jenkins-ios-shared-lib']) _

import groovy.json.JsonSlurperClassic
import mega.privacy.android.pipeline.DefaultParserWrapper
import org.apache.commons.cli.CommandLine
import org.apache.commons.cli.CommandLineParser
import org.apache.commons.cli.Option
import org.apache.commons.cli.Options

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
        MEGA_IOS_PROJECT_ID = credentials('MEGA_IOS_PROJECT_ID')
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
                
                statusNotifier.postSuccess(message, env.MEGA_IOS_PROJECT_ID)

                def parameters = parseParameters(env.gitlabTriggerPhrase)
                if (parameters[0]) {
                    def command = "announce_release"
    
                    if (parameters[1]) {
                        command += " --hotfix-build true"
                    }
                    
                    if (parameters[2]) {
                        command += " --first-announcement true"
                    }

                    statusNotifier.postMessage(command, env.MEGA_IOS_PROJECT_ID, "good")
                }
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

                statusNotifier.postFailure(message, env.MEGA_IOS_PROJECT_ID)
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
                    script {
                        envInjector.injectEnvs {
                            sh "bundle install"
                        }
                    }
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
                            script {
                                envInjector.injectEnvs {
                                    sh "bundle exec fastlane set_time_as_build_number"
                                    sh "bundle exec fastlane fetch_version_number"
                                    env.MEGA_BUILD_NUMBER = readFile(file: './fastlane/build_number.txt')
                                    env.MEGA_VERSION_NUMBER = readFile(file: './fastlane/version_number.txt')
                                }
                            }
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
                            script {
                                envInjector.injectEnvs {
                                    dir("scripts/") {
                                        sh 'python3 check_translations.py'
                                    }
                                }
                            }
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
                            script {
                                envInjector.injectEnvs {
                                    sh 'bundle exec fastlane download_metadata'
                                }
                            }
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
                            script {
                                envInjector.injectEnvs {
                                    withCredentials([file(credentialsId: 'ios_firebase_credentials', variable: 'firebase_credentials')]) {
                                        sh "cp \$firebase_credentials service_credentials_file.json"
                                        sh "bundle exec fastlane download_device_ids_from_firebase"
                                        sh "bundle exec fastlane upload_device_ids_to_developer_portal"
                                        sh "rm service_credentials_file.json"
                                    } 
                                }
                            }
                        }
                    }  
                }
            }
        }
        
        stage('Install Dependencies') {
            when { 
                anyOf {
                    expression { return env.gitlabTriggerPhrase ==~ /^deliver_appStore.*$/ }
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
                                script {
                                    envInjector.injectEnvs {
                                        sh "git submodule foreach --recursive git clean -xfd"
                                        sh "git submodule sync --recursive"
                                        sh "git submodule update --init --recursive"
                                        dir("Modules/DataSource/MEGAChatSDK/Sources/MEGAChatSDK/src/") {
                                            sh "cmake -P genDbSchema.cmake"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                stage('Downloading third party libraries') {
                    steps {
                        gitlabCommitStatus(name: 'Downloading third party libraries') {
                            script {
                                envInjector.injectEnvs {
                                    sh "bundle exec fastlane configure_sdk_and_chat_library use_cache:true"
                                }
                            }
                        }
                    }
                }

                stage('Install certificate and provisioning profiles in temporary keychain') {
                    steps {
                        gitlabCommitStatus(name: 'Install certificate and provisioning profiles in temporary keychain') {
                            script {
                                envInjector.injectEnvs {
                                    sh "bundle exec fastlane create_temporary_keychain"
                                    withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                                        sh "bundle exec fastlane install_certificate_and_profile_to_temp_keychain type:'appstore' readonly:true"
                                        def readonly = "true"
                                        if (env.gitlabTriggerPhrase == 'deliver_qa_include_new_devices') {
                                            readonly = "false"
                                        }

                                        sh "bundle exec fastlane install_certificate_and_profile_to_temp_keychain type:'development' readonly:${readonly}"
                                        sh "bundle exec fastlane install_certificate_and_profile_to_temp_keychain type:'adhoc' readonly:${readonly}"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Archive appstore') {
            when { 
                anyOf {
                    expression { return env.gitlabTriggerPhrase ==~ /^deliver_appStore.*$/ }
                }
            }
            steps {
                gitlabCommitStatus(name: 'Archive appstore') {
                    withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                        script {
                            envInjector.injectEnvs {
                                sh "bundle exec fastlane archive_appstore"
                                env.MEGA_BUILD_ARCHIVE_PATH = readFile(file: './fastlane/archive_path.txt')
                            }
                        }
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
                        script {
                            envInjector.injectEnvs {
                                sh "bundle exec fastlane archive_adhoc"
                            }
                        }
                    }
                }
            }
        }

        stage('Upload') {
            parallel {
                stage('Upload to Testflight') {    
                    when { 
                        anyOf {
                            expression { return env.gitlabTriggerPhrase ==~ /^deliver_appStore.*$/ }
                        }
                    } 
                    steps {
                        gitlabCommitStatus(name: 'Upload to Testflight') {
                            withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                                script {
                                    envInjector.injectEnvs {
                                        sh "bundle exec fastlane upload_to_itunesconnect"
                                    }
                                }
                            }
                        }
                    }
                }

                stage('Upload symbols to crashlytics') {
                    when { 
                        anyOf {
                            expression { return env.gitlabTriggerPhrase ==~ /^deliver_appStore.*$/ }
                            environment name: 'gitlabTriggerPhrase', value: 'deliver_qa'
                            environment name: 'gitlabTriggerPhrase', value: 'deliver_qa_include_new_devices'
                            environment name: 'GIT_BRANCH', value: 'origin/develop'
                        }
                    }
                    steps {
                        script {
                            envInjector.injectEnvs {
                                if (env.gitlabTriggerPhrase ==~ /^deliver_appStore.*$/) {
                                    gitlabCommitStatus(name: 'Upload appstore symbols to crashlytics') {
                                        sh "bundle exec fastlane upload_symbols configuration:Release"
                                    }
                                } else {
                                    gitlabCommitStatus(name: 'Upload QA symbols to crashlytics') {
                                        sh "bundle exec fastlane upload_symbols configuration:QA"
                                    }
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
                            script {
                                envInjector.injectEnvs {
                                    withCredentials([file(credentialsId: 'ios_firebase_credentials', variable: 'firebase_credentials')]) {
                                        sh "cp \$firebase_credentials service_credentials_file.json"
                                        sh "bundle exec fastlane upload_build_to_firebase configuration:QA"
                                    } 
                                }
                            }
                        }
                    }
                }

                stage('Prepare archive zip to be uploaded to MEGA') {
                    when { 
                        anyOf {
                            expression { return env.gitlabTriggerPhrase ==~ /^deliver_appStore.*$/ }
                        }
                    }
                    steps {
                        gitlabCommitStatus(name: 'Prepare archive zip to be uploaded to MEGA') {
                            script {
                                envInjector.injectEnvs {
                                    withCredentials([string(credentialsId: 'ios-mega-artifactory-upload', variable: 'ARTIFACTORY_TOKEN')]) {
                                        def fileName = "${env.MEGA_VERSION_NUMBER}-${env.MEGA_BUILD_NUMBER}.zip"
                                        env.zipPath = "${WORKSPACE}/${fileName}"
                                        env.targetPath = "https://artifactory.developers.mega.co.nz/artifactory/ios-mega/${fileName}"
                                        sh "bundle exec fastlane zip_Archive archive_path:\'${env.MEGA_BUILD_ARCHIVE_PATH}\' zip_path:${env.zipPath}"
                                        sh 'curl -H\"Authorization: Bearer $ARTIFACTORY_TOKEN\" -T ${zipPath} \"${targetPath}\"'
                                        sh 'rm ${zipPath}'
                                    }
                                } 
                            }
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
                            script {
                                envInjector.injectEnvs {
                                    dir("scripts/AppMetadataUpdater/") {
                                        sh 'swift run AppMetadataUpdater --update-release-notes -v $MEGA_VERSION_NUMBER \"$TRANSIFIX_AUTHORIZATION_TOKEN\"'
                                    }
                                    sh 'bundle exec fastlane upload_metadata_to_appstore_connect'
                                }
                            }
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
                            script {
                                envInjector.injectEnvs {
                                    dir("scripts/AppMetadataUpdater/") {
                                        sh 'swift run AppMetadataUpdater --update-description \"$TRANSIFIX_AUTHORIZATION_TOKEN\"'
                                    }
                                    sh 'bundle exec fastlane upload_metadata_to_appstore_connect'
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Delete temporary keychain') {
            when { 
                anyOf {
                    expression { return env.gitlabTriggerPhrase ==~ /^deliver_appStore.*$/ }
                    environment name: 'gitlabTriggerPhrase', value: 'deliver_qa'
                    environment name: 'gitlabTriggerPhrase', value: 'deliver_qa_include_new_devices'
                    environment name: 'GIT_BRANCH', value: 'origin/develop'
                }
            }
            steps {
                gitlabCommitStatus(name: 'Delete temporary keychain') {
                    script {
                        envInjector.injectEnvs {
                            sh "bundle exec fastlane delete_temporary_keychain"
                        }
                    }
                }
            }
        }
    }
}

private def parseParameters(String fullCommand) {
    if (fullCommand == null) {
        println("This job was not triggered by comment")
        return [false]  // Default return value
    }

    println("Parsing parameters")
    String[] parameters = fullCommand.split("\\s+(?=([^\"]*\"[^\"]*\")*[^\"]*\$)")

    Options options = new Options()
    Option announceReleaseOption = Option
            .builder("ar")
            .longOpt("announce-release")
            .argName("Announce Release")
            .hasArg()
            .required(false)
            .desc("Specify the next release version to be announced")
            .build()
    Option hotfixBuild = Option
            .builder("hfb")
            .longOpt("hotfix-build")
            .argName("Hotfix Build")
            .hasArg()
            .required(false)
            .desc("Specify if this is a hotfix build")
            .build()
    Option firstAnnouncement = Option
            .builder("fa")
            .longOpt("first-announcement")
            .argName("First announcement")
            .hasArg()
            .required(false)
            .desc("Specify if this is the first announcement of the release")
            .build()
            
    options.addOption(announceReleaseOption)
    options.addOption(hotfixBuild)
    options.addOption(firstAnnouncement)

    CommandLineParser commandLineParser = new DefaultParserWrapper()
    CommandLine commandLine = commandLineParser.parse(options, parameters)

    boolean shouldAnnounceRelease = false  // Default to false
    boolean isHotfixBuild = false  // Default to false
    boolean isFirstAnnouncement = false  // Default to false

    if (commandLine.hasOption("ar")) {
        shouldAnnounceRelease = Boolean.parseBoolean(commandLine.getOptionValue("ar"))
    }

    if (commandLine.hasOption("hfb")) {
        isHotfixBuild = Boolean.parseBoolean(commandLine.getOptionValue("hfb"))
    }

    if (commandLine.hasOption("fa")) {
        isFirstAnnouncement = Boolean.parseBoolean(commandLine.getOptionValue("fa"))
    }

    println("should announce release: $shouldAnnounceRelease")
    println("is hotfix build: $isHotfixBuild")
    println("is first announcement: $isFirstAnnouncement")
    return [shouldAnnounceRelease, isHotfixBuild, isFirstAnnouncement]
}