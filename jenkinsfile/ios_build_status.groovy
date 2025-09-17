import groovy.transform.Field
@Library('jenkins-ios-shared-lib') _

// This is global variable is required to check if the unit test step was reached or not. This is required to avoid running the parse_and_upload_build_warnings_and_errors lane if the unit test step was not reached.
@Field boolean runUnitTestsStepReached = false

def postWarningAboutFilesChanged(int maxNumberOfFilesAllowed) {
    if (!runUnitTestsStepReached) {
        return
    }

    withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
        def script = "git diff --name-only origin/develop...origin/${env.BRANCH_NAME} -- \"*.swift\" | wc -l"
        def numberOfFiles = sh(script: script, returnStdout: true).trim() ?: "0"

        if (numberOfFiles.toInteger() <= maxNumberOfFilesAllowed) {
            return
        }

        def message = ":warning: Over 10 `.swift` files changed, please explain why you need to do this change or break the MR into smaller ones"
        statusNotifier.postMessage(message, env.MEGA_IOS_PROJECT_ID, "warning")
    }
}

def executeFastlaneTask(taskCommand) {
    if (!runUnitTestsStepReached) {
        return
    }

    withCredentials([usernamePassword(credentialsId: 'Gitlab-Access-Token', usernameVariable: 'USERNAME', passwordVariable: 'TOKEN')]) {
        script {
            envInjector.injectEnvs {
                def mr_number = commonUtils.getMRNumber()
                if (mr_number != null && !mr_number.isEmpty()) {
                    try {
                        sh "bundle exec fastlane ${taskCommand} mr:${mr_number} token:${TOKEN}"
                    } catch (Exception e) {
                        error("Fastlane task ${taskCommand} failed: ${e.message}")
                    }
                }
            }
        }
    }
}

def postBuildWarningsAndError() {
    executeFastlaneTask("parse_and_upload_build_warnings_and_errors")
}

def parseAndUploadCodeCoverage() {
    executeFastlaneTask("parse_and_upload_code_coverage")
}

def postAppSizeToMR() {
    executeFastlaneTask("post_app_size_to_mr")
}

pipeline {
    agent { label 'mac-jenkins-slave-ios-xcode-26' }
    options {
        timeout(time: 45, unit: 'MINUTES') 
        gitLabConnection('GitLabConnection')
        gitlabCommitStatus(name: 'Jenkins')
        ansiColor('xterm')
    }
    environment {
        MEGA_IOS_PROJECT_ID = credentials('MEGA_IOS_PROJECT_ID')
    }
    post { 
        failure {
            script {
                statusNotifier.postFailure(":x: Build failed", env.MEGA_IOS_PROJECT_ID)
                postBuildWarningsAndError()
            }
            
            updateGitlabCommitStatus name: 'Jenkins', state: 'failed'
        }
        success {
            script {
                envInjector.injectEnvs {
                    statusNotifier.postSuccess(":white_check_mark: Build status check succeeded", env.MEGA_IOS_PROJECT_ID)
                    parseAndUploadCodeCoverage()
                    postBuildWarningsAndError()
                    postAppSizeToMR()
                }
            }

            updateGitlabCommitStatus name: 'Jenkins', state: 'success'
        }
        aborted {
            script {
                statusNotifier.postFailure(":x: Build aborted", env.MEGA_IOS_PROJECT_ID)
            }
        }
        always {
            script {
                envInjector.injectEnvs {
                    postWarningAboutFilesChanged(10)
                }
            }
        }
        cleanup {
            deleteDir() /* clean up our workspace */
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

        stage('Installing dependencies') {
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
            }
        }

        stage('main app - Run Unit test and generate code coverage') {
            steps {
                lock(resource: "${env.NODE_NAME}", quantity: 1) {
                    gitlabCommitStatus(name: 'main app - Run unit test and generate code coverage') {
                        withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                            script {
                                envInjector.injectEnvs {
                                    runUnitTestsStepReached = true
                                    sh "bundle exec fastlane run_tests_app"
                                    sh "bundle exec fastlane get_coverage"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
