@Library('jenkins-ios-shared-lib') _

pipeline {
    agent { label 'mac-jenkins-slave-ios' }
    options {
        timeout(time: 1, unit: 'HOURS') 
        gitLabConnection('GitLabConnection')
        ansiColor('xterm')
    }
    environment {
        APP_STORE_CONNECT_KEY_ID = credentials('APP_STORE_CONNECT_KEY_ID')
        APP_STORE_CONNECT_ISSUER_ID = credentials('APP_STORE_CONNECT_ISSUER_ID')
        APP_STORE_CONNECT_API_KEY_B64 = credentials('APP_STORE_CONNECT_API_KEY_B64')
        APP_STORE_CONNECT_API_KEY_VALUE = credentials('APP_STORE_CONNECT_API_KEY_VALUE')
        TRANSIFIX_AUTHORIZATION_TOKEN = credentials('TRANSIFIX_AUTHORIZATION_TOKEN')
        MEGA_IOS_PROJECT_ID = credentials('MEGA_IOS_PROJECT_ID')
    }
    post { 
        failure {
            script {
                def message = ":x: Failed to submit version ${params.VERSION_NUMBER} (${params.BUILD_NUMBER}) to the App Store"
                statusNotifier.postFailure(message, env.MEGA_IOS_PROJECT_ID)
            }
        }
        success {
            script {
                def message = ":rocket: ${params.VERSION_NUMBER} (${params.BUILD_NUMBER}) has been submitted to App Store for review."
                statusNotifier.postSuccess(message, env.MEGA_IOS_PROJECT_ID)
            }
        }
        cleanup {
            cleanWs()
        }
    }
    stages {
        stage('Setup') {
            parallel {
                stage('Bundle install') {
                    steps {
                        script {
                            envInjector.injectEnvs {
                                sh 'bundle install'
                            }
                        }
                    }
                }
                stage('Download app metadata') {
                    steps {
                        script {
                            envInjector.injectEnvs {
                                sh 'bundle exec fastlane download_metadata' 
                            }
                        }
                    }
                }
            }
        } 
        
        stage('Update what\'s new and app description to appstore connect and Submit app for review') {
            steps {
                script {
                    envInjector.injectEnvs {
                        dir("scripts/AppMetadataUpdater/") {
                            env.VERSION_NUMBER = params.VERSION_NUMBER
                            sh 'swift run AppMetadataUpdater --update-description --update-release-notes -v $VERSION_NUMBER \"$TRANSIFIX_AUTHORIZATION_TOKEN\"'
                        }

                        sh "bundle exec fastlane submit_review phased_release:${params.PHASED_RELEASE} version_number:${params.VERSION_NUMBER} build_number:${params.BUILD_NUMBER}"
                    }
                }
            }
        }
    }
}