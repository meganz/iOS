@Library('jenkins-android-shared-lib') _

def injectEnvironments(Closure body) {
    withEnv([
        "PATH=/var/lib/jenkins/.rbenv/shims:/var/lib/jenkins/.rbenv/bin:/Applications/MEGAcmd.app/Contents/MacOS:/Applications/CMake.app/Contents/bin:$PATH:/usr/local/bin:/opt/brew/bin",
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
                def message = ":rocket: Create tag and sync from master was successful"

                if (hasGitLabMergeRequest()) {
                    postGitLabComment(message, env.gitlabMergeRequestIid)
                }
            }
        }
        failure {
            script {
                def message = ":x: The Create tag and sync from master failed"
                if (hasGitLabMergeRequest()) {
                    def mrNumber = env.gitlabMergeRequestIid

                    withCredentials([usernameColonPassword(credentialsId: 'Jenkins-Login', variable: 'CREDENTIALS')]) {
                        sh 'curl -u $CREDENTIALS ${BUILD_URL}/consoleText -o console.txt'
                    }

                    withCredentials([usernamePassword(credentialsId: 'Gitlab-Access-Token', usernameVariable: 'USERNAME', passwordVariable: 'TOKEN')]) {
                        final String response = sh(script: 'curl -s --request POST --header PRIVATE-TOKEN:$TOKEN --form file=@console.txt \"$GITLAB_API_BASE_URL\"/projects/\"$MEGA_IOS_PROJECT_ID\"/uploads', returnStdout: true).trim()
                        def json = new groovy.json.JsonSlurperClassic().parseText(response)
                        postGitLabComment("${message} <br />Build Log: ${json.markdown}", mrNumber)
                    }
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

        stage('Create Tag and Sync from Master') {
            steps {
                withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                    injectEnvironments({
                        script {
                            util.useGpg() {
                                dir("scripts/CreateTagAndSyncFromMaster/") {
                                     sh 'swift run CreateTagAndSyncFromMaster --transifex-authorization \"$TRANSIFIX_AUTHORIZATION_TOKEN\" --release-notes-resource-id \"$IOS_MEGA_CHANGELOG_RESOURCE_ID\" --gitlab-base-url \"$GITLAB_API_BASE_URL\" --gitlab-token \"$GITLAB_BEARER_TOKEN\" --project-id \"$MEGA_IOS_PROJECT_ID\" --branch \"$GIT_BRANCH\"'
                                }
                            }
                        }
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

private def postGitLabComment(String message, String mrNumber) {
    withCredentials([usernamePassword(credentialsId: 'Gitlab-Access-Token', usernameVariable: 'USERNAME', passwordVariable: 'TOKEN')]) {
        env.MARKDOWN_LINK = message
        env.MERGE_REQUEST_URL = "${GITLAB_API_BASE_URL}/projects/${MEGA_IOS_PROJECT_ID}/merge_requests/${mrNumber}/notes"
        sh 'curl --request POST --header PRIVATE-TOKEN:$TOKEN --form body=\"${MARKDOWN_LINK}\" ${MERGE_REQUEST_URL}'
    }
}
