@Library('jenkins-ios-shared-lib') _

pipeline {
    agent { label 'mac-jenkins-slave-ios' }
    options {
        timeout(time: 3, unit: 'HOURS') 
        gitLabConnection('GitLabConnection')
        ansiColor('xterm')
    }
    environment {
        TRANSIFIX_AUTHORIZATION_TOKEN = credentials('TRANSIFIX_AUTHORIZATION_TOKEN')
        IOS_MEGA_CHANGELOG_RESOURCE_ID = credentials('IOS_MEGA_CHANGELOG_RESOURCE_ID')
        JIRA_BASE_URL = credentials('JIRA_BASE_URL')
        JIRA_TOKEN = credentials('JIRA_TOKEN')
        MEGA_IOS_JIRA_PROJECT_NAME_AND_ID_TABLE = credentials('MEGA_IOS_JIRA_PROJECT_NAME_AND_ID_TABLE')
        GITLAB_API_BASE_URL = credentials('GITLAB_API_BASE_URL')
        GITLAB_BEARER_TOKEN = credentials('GITLAB_BEARER_TOKEN')
        GITHUB_ACCESS_TOKEN = credentials('bcb8c4fa-5d72-473a-89f9-2c072e68ef9a')
        MEGA_IOS_PROJECT_ID = credentials('MEGA_IOS_PROJECT_ID')
    }
    post {
        success {
            script {
                statusNotifier.postSuccess(":rocket: The Merge Release script execution was successful", env.MEGA_IOS_PROJECT_ID)
            }
        }
        failure {
            script {
                statusNotifier.postFailure(":x: The Merge Release script execution failed", env.MEGA_IOS_PROJECT_ID)
            }                    
        }
        cleanup {
            cleanWs()
        }
    }
    stages {
        stage('Bundle install') {
            steps {
                script {
                    envInjector.injectEnvs {
                        sh "bundle install"
                    }
                }
            }
        }
        
        stage('Install Dependencies') {
            steps {
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

        stage('merge release') {
            steps {
                withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                    script {
                        envInjector.injectEnvs {
                            dir("scripts/MergeRelease/") {
                                sh 'swift run MergeRelease --transifex-authorization \"$TRANSIFIX_AUTHORIZATION_TOKEN\" --release-notes-resource-id \"$IOS_MEGA_CHANGELOG_RESOURCE_ID\" --gitlab-base-url \"$GITLAB_API_BASE_URL\" --gitlab-token \"$GITLAB_BEARER_TOKEN\" --jira-base-url-string \"$JIRA_BASE_URL\" --jira-authorization \"$JIRA_TOKEN\" --jira-projects \"$MEGA_IOS_JIRA_PROJECT_NAME_AND_ID_TABLE\" --github-access-token \"$GITHUB_ACCESS_TOKEN\" --project-id \"$MEGA_IOS_PROJECT_ID\"'
                            }
                        }
                    }
                }
            }
        }
    }
}