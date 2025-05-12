@Library(['jenkins-android-shared-lib', 'jenkins-ios-shared-lib']) _

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
                statusNotifier.postSuccess(":rocket: Create tag and sync from master was successful", env.MEGA_IOS_PROJECT_ID)
            }
        }
        failure {
            script {
                statusNotifier.postFailure(":x: The Create tag and sync from master failed", env.MEGA_IOS_PROJECT_ID)
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

        stage('Create Tag and Sync from Master') {
            steps {
                withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                    script {
                        envInjector.injectEnvs {
                            util.useGpg() {
                                dir("Modules/MEGASharedRepo/scripts/CreateTagAndSyncFromMaster/") {
                                     sh 'swift run CreateTagAndSyncFromMaster --transifex-authorization \"$TRANSIFIX_AUTHORIZATION_TOKEN\" --release-notes-resource-id \"$IOS_MEGA_CHANGELOG_RESOURCE_ID\" --gitlab-base-url \"$GITLAB_API_BASE_URL\" --gitlab-token \"$GITLAB_BEARER_TOKEN\" --project-id \"$MEGA_IOS_PROJECT_ID\" --branch \"$GIT_BRANCH\" --default-branch master'
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
