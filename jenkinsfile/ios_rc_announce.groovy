@Library('jenkins-android-shared-lib') _

import groovy.json.JsonSlurperClassic
import mega.privacy.android.pipeline.DefaultParserWrapper
import org.apache.commons.cli.CommandLine
import org.apache.commons.cli.CommandLineParser
import org.apache.commons.cli.Option
import org.apache.commons.cli.Options

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
        TRANSIFIX_AUTHORIZATION_TOKEN = credentials('TRANSIFIX_AUTHORIZATION_TOKEN')
        IOS_MEGA_CHANGELOG_RESOURCE_ID = credentials('IOS_MEGA_CHANGELOG_RESOURCE_ID')
        JIRA_BASE_URL = credentials('JIRA_BASE_URL')
        JIRA_TOKEN = credentials('JIRA_TOKEN')
        MEGA_IOS_JIRA_PROJECT_NAME_AND_ID_TABLE = credentials('MEGA_IOS_JIRA_PROJECT_NAME_AND_ID_TABLE')
        RELEASE_ANNOUNCEMENT_SLACK_TOKEN = credentials('RELEASE_ANNOUNCEMENT_SLACK_TOKEN')
        MOBILE_DEV_TEAM_SLACK_CHANNEL_ID = credentials('MOBILE_DEV_TEAM_SLACK_CHANNEL_ID')
        MEGA_IOS_TESTFLIGHT_BASE_URL = credentials('MEGA_IOS_TESTFLIGHT_BASE_URL')
        IOS_RC_TEAM_SLACK_CHANNEL_IDS = credentials('IOS_RC_TEAM_SLACK_CHANNEL_IDS')
        GITLAB_API_BASE_URL = credentials('GITLAB_API_BASE_URL')
    }
    post {
        success {
            script {
                def message = ":rocket: The RC announcement was successful"

                if (hasGitLabMergeRequest()) {
                    def mrNumber = env.gitlabMergeRequestIid

                    withCredentials([usernamePassword(credentialsId: 'Gitlab-Access-Token', usernameVariable: 'USERNAME', passwordVariable: 'TOKEN')]) {
                        env.MARKDOWN_LINK = message
                        env.MERGE_REQUEST_URL = "${GITLAB_API_BASE_URL}/projects/193/merge_requests/${mrNumber}/notes"
                        sh 'curl --request POST --header PRIVATE-TOKEN:$TOKEN --form body=\"${MARKDOWN_LINK}\" ${MERGE_REQUEST_URL}'
                    }
                }
            }
        }
        failure {
            script {
                def message = ":x: The RC announcement failed"

                if (hasGitLabMergeRequest()) {
                    def mrNumber = env.gitlabMergeRequestIid

                    withCredentials([usernameColonPassword(credentialsId: 'Jenkins-Login', variable: 'CREDENTIALS')]) {
                        sh 'curl -u $CREDENTIALS ${BUILD_URL}/consoleText -o console.txt'
                    }

                    withCredentials([usernamePassword(credentialsId: 'Gitlab-Access-Token', usernameVariable: 'USERNAME', passwordVariable: 'TOKEN')]) {
                        final String response = sh(script: 'curl -s --request POST --header PRIVATE-TOKEN:$TOKEN --form file=@console.txt \"$GITLAB_API_BASE_URL\"/projects/193/uploads', returnStdout: true).trim()
                        def json = new groovy.json.JsonSlurperClassic().parseText(response)
                        env.MARKDOWN_LINK = "${message} <br />Build Log: ${json.markdown}"
                        env.MERGE_REQUEST_URL = "${GITLAB_API_BASE_URL}/projects/193/merge_requests/${mrNumber}/notes"
                        sh 'curl --request POST --header PRIVATE-TOKEN:$TOKEN --form body=\"${MARKDOWN_LINK}\" ${MERGE_REQUEST_URL}'
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

        stage('Announce RC') {
            steps {
                withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                    injectEnvironments({
                        script {
                            dir("scripts/ReleaseCandidateAnnouncement/") {
                                def parameters = parseParameters(env.gitlabTriggerPhrase)
                                env.NEXT_RELEASE_VERSION = parameters[0]

                                sh 'swift run ReleaseCandidateAnnouncement --transifex-authorization \"$TRANSIFIX_AUTHORIZATION_TOKEN\" --release-notes-resource-id \"$IOS_MEGA_CHANGELOG_RESOURCE_ID\" --jira-base-url-string \"$JIRA_BASE_URL\" --jira-authorization \"$JIRA_TOKEN\" --jira-projects \"$MEGA_IOS_JIRA_PROJECT_NAME_AND_ID_TABLE\" --slack-authorization \"$RELEASE_ANNOUNCEMENT_SLACK_TOKEN\" --code-freeze-slack-channel-ids \"$MOBILE_DEV_TEAM_SLACK_CHANNEL_ID\" --testflight-base-url \"$MEGA_IOS_TESTFLIGHT_BASE_URL\" --release-candidate-slack-channel-ids \"$IOS_RC_TEAM_SLACK_CHANNEL_IDS\" --next-release-version \"$NEXT_RELEASE_VERSION\"'
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

private def parseParameters(String fullCommand) {
    println("Parsing parameters")
    String[] parameters = fullCommand.split("\\s+(?=([^\"]*\"[^\"]*\")*[^\"]*\$)")

    Options options = new Options()
    Option releaseVersionOption = Option
            .builder("nrv")
            .longOpt("next-release-version")
            .argName("Next Release Version")
            .hasArg()
            .desc("Next release version which is to create in Jira")
            .build()
    options.addOption(releaseVersionOption)

    CommandLineParser commandLineParser = new DefaultParserWrapper()
    CommandLine commandLine = commandLineParser.parse(options, parameters)

    String nextReleaseVersion = commandLine.getOptionValue("nrv")

    println("nextReleaseVersion: $nextReleaseVersion")

    return [nextReleaseVersion]
}


