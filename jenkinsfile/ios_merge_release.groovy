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
                def message = ":rocket: The Merge Release script execution was successful"
                slackSend color: "good", message: "${message}"
            }
        }
        failure {
            script {
                def message = ":x: The Merge Release script execution failed"
                withCredentials([usernameColonPassword(credentialsId: 'Jenkins-Login', variable: 'CREDENTIALS')]) {
                    sh 'curl -u $CREDENTIALS ${BUILD_URL}/consoleText -o console.txt'
                    slackUploadFile filePath:"console.txt", initialComment: "${message}"
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
                injectEnvironments({
                    sh "bundle install"
                })
            }
        }
        
        stage('Install Dependencies') {
            steps {
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

        stage('Announce RC') {
            steps {
                withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                    injectEnvironments({
                        script {
                            dir("scripts/MergeRelease/") {
                                sh 'swift run MergeRelease --transifex-authorization \"$TRANSIFIX_AUTHORIZATION_TOKEN\" --release-notes-resource-id \"$IOS_MEGA_CHANGELOG_RESOURCE_ID\" --gitlab-base-url \"$GITLAB_API_BASE_URL\" --gitlab-token \"$GITLAB_BEARER_TOKEN\" --jira-base-url-string \"$JIRA_BASE_URL\" --jira-authorization \"$JIRA_TOKEN\" --jira-projects \"$MEGA_IOS_JIRA_PROJECT_NAME_AND_ID_TABLE\" --github-access-token \"$GITHUB_ACCESS_TOKEN\" --project-id \"$MEGA_IOS_PROJECT_ID\"'
                            }
                        }
                    })
                }
            }
        }
    }
}