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
        MEGA_IOS_PROJECT_ID = credentials('MEGA_IOS_PROJECT_ID')
    }
    post {
        success {
            script {
                def message = ":rocket: The RC announcement was successful"
                message = env.gitlabTriggerPhrase == 'jira_create_version' ? ":rocket: Successfully created the release version in Jira"
                statusNotifier.postSuccess(message, env.MEGA_IOS_PROJECT_ID)
            }
        }
        failure {
            script {
                def message = ":x: The RC announcement failed"
                message = env.gitlabTriggerPhrase == 'jira_create_version' ? ":x: Failed to create the release version in Jira" : message
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
                script {
                    envInjector.injectEnvs {
                        sh "bundle install"
                    }
                }
            }
        }
        
        stage('Install Dependencies') {
            when { 
                anyOf {
                    environment name: 'gitlabTriggerPhrase', value: 'announce_release' 
                }
            }
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

        stage('Announce RC') {
            when { 
                anyOf {
                    environment name: 'gitlabTriggerPhrase', value: 'announce_release' 
                }
            }
            steps {
                withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                    script {
                        envInjector.injectEnvs {
                            dir("scripts/ReleaseCandidateAnnouncement/") {
                                def parameters = parseParameters(env.gitlabTriggerPhrase)
                                env.NEXT_RELEASE_VERSION = parameters[0]

                                sh 'swift run ReleaseCandidateAnnouncement --transifex-authorization \"$TRANSIFIX_AUTHORIZATION_TOKEN\" --release-notes-resource-id \"$IOS_MEGA_CHANGELOG_RESOURCE_ID\" --jira-base-url-string \"$JIRA_BASE_URL\" --jira-authorization \"$JIRA_TOKEN\" --jira-projects \"$MEGA_IOS_JIRA_PROJECT_NAME_AND_ID_TABLE\" --slack-authorization \"$RELEASE_ANNOUNCEMENT_SLACK_TOKEN\" --code-freeze-slack-channel-ids \"$MOBILE_DEV_TEAM_SLACK_CHANNEL_ID\" --testflight-base-url \"$MEGA_IOS_TESTFLIGHT_BASE_URL\" --release-candidate-slack-channel-ids \"$IOS_RC_TEAM_SLACK_CHANNEL_IDS\" --next-release-version \"$NEXT_RELEASE_VERSION\"'
                            }
                        }
                    }
                }
            }
        }

        stage('Create Jira version in all projects') {
            when { 
                anyOf {
                    environment name: 'gitlabTriggerPhrase', value: 'jira_create_version' 
                }
            }
            steps {
                withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                    script {
                        envInjector.injectEnvs {
                            dir("scripts/CreateReleaseVersionInJira/") {
                                sh 'swift run CreateReleaseVersionInJira --jira-authorization \"$JIRA_TOKEN\" --jira-projects \"$MEGA_IOS_JIRA_PROJECT_NAME_AND_ID_TABLE\" --jira-base-url-string \"$JIRA_BASE_URL\"'
                            }
                        }
                    }
                }
            }
        }
    }
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


