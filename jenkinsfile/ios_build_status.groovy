import groovy.transform.Field
@Library('jenkins-ios-shared-lib') _

// This is global variable is required to check if the unit test step was reached or not. This is required to avoid running the parse_and_upload_build_warnings_and_errors lane if the unit test step was not reached.
@Field boolean runUnitTestsStepReached = false

NODE_LABELS = 'mac-jenkins-slave-ios-xcode-26'

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

def executeFastlaneTask(taskCommand, checkRunUnitTestsStep = true) {
    if (checkRunUnitTestsStep && !runUnitTestsStepReached) {
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

def postBuildWarnings() {
    executeFastlaneTask("post_build_warnings")
}

def postCoverageReportToMR() {
    executeFastlaneTask("post_coverage_report_to_mr")
}

def postErrors() {
    executeFastlaneTask("post_errors", false)
}

def postAppSizeToMR() {
    executeFastlaneTask("post_app_size_to_mr")
}

def setupProjectDependencies() {
    sh "bundle install"
    sh "git submodule foreach --recursive git clean -xfd"
    sh "git submodule sync --recursive"
    sh "git submodule update --init --recursive"
    dir("Modules/DataSource/MEGAChatSDK/Sources/MEGAChatSDK/src/") {
        sh "cmake -P genDbSchema.cmake"
    }
    sh "bundle exec fastlane configure_sdk_and_chat_library use_cache:true"
}

pipeline {
    agent { label NODE_LABELS }
    options {
        timeout(time: 45, unit: 'MINUTES') 
        gitLabConnection('GitLabConnection')
        gitlabCommitStatus(name: 'Jenkins')
        ansiColor('xterm')
        throttleJobProperty(
            categories: ['ios-builds'],  
            throttleEnabled: true,
            throttleOption: 'category',  
            maxConcurrentPerNode: 0,
            maxConcurrentTotal: 3
        )
    }
    environment {
        MEGA_IOS_PROJECT_ID = credentials('MEGA_IOS_PROJECT_ID')
    }
    post { 
        failure {
            script {
                statusNotifier.postFailure(":x: Build failed", env.MEGA_IOS_PROJECT_ID)
                dir("scripts/WarningParsingKit/") {
                    sh 'swift run'
                }
                postBuildWarnings()
                dir("scripts/ErrorParsingKit/") {
                    sh 'swift run ErrorParsingKit --is-main-app-target true'
                }

                artifactStasher.unstashArtifact('swift-packages-errors')

                def packagesErrors = fileExists('outputs/errors_packages.md') ? 
                                        readFile('outputs/errors_packages.md') : ''
                def mainAppErrors = fileExists('outputs/errors.md') ? 
                                        readFile('outputs/errors.md') : ''
                def separator = (packagesErrors && mainAppErrors) ? '\n\n' : ''
                    
                writeFile file: 'outputs/errors.md', 
                         text: "${mainAppErrors}${separator}${packagesErrors}"
                         
                postErrors()
            }
            
            updateGitlabCommitStatus name: 'Jenkins', state: 'failed'
        }
        success {
            script {
                envInjector.injectEnvs {
                    dir("scripts/CodeCoverageParserKit/") {
                        sh 'swift run CodeCoverageParserKit --should-include-header true --targets \"MEGA.app,MEGAIntent.appex,MEGANotifications.appex,MEGAPicker.appex,MEGAPickerFileProvider.appex,MEGAWidgetExtension.appex\"'
                    }
                    artifactStasher.unstashArtifact('swift-packages-coverage')
                    if (fileExists('fastlane/code_coverage_packages.md')) {
                        def packagesCoverage = readFile('fastlane/code_coverage_packages.md')
                        def mainCoverage = fileExists('fastlane/code_coverage.md') ? 
                                           readFile('fastlane/code_coverage.md') : ''
                        
                        writeFile file: 'fastlane/code_coverage.md', 
                                 text: "${mainCoverage}${packagesCoverage}"
                    }
                    dir("scripts/WarningParsingKit/") {
                        sh 'swift run'
                    }
                    
                    statusNotifier.postSuccess(":white_check_mark: Build status check succeeded", env.MEGA_IOS_PROJECT_ID)
                    postBuildWarnings()
                    postCoverageReportToMR()
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
            cleanWs(
                cleanWhenFailure: true,
                cleanWhenAborted: true,
                cleanWhenNotBuilt: true,
                cleanWhenUnstable: true,
                cleanWhenSuccess: true,
                disableDeferredWipeout: true,
                deleteDirs: true
            )
        }
    }
    stages {
        stage('Run Unit tests') {
            failFast false
            parallel {
                stage('Main app - Run Unit test and generate code coverage') {
                    steps {
                        gitlabCommitStatus(name: 'Main app - Run Unit test and generate code coverage') {
                            withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                                script {
                                    envInjector.injectEnvs {
                                        setupProjectDependencies()
                                        runUnitTestsStepReached = true
                                        sh "bundle exec fastlane run_tests_app"
                                    }
                                }
                            }
                        }
                    }
                }
                stage('Swift Packages - Run Unit test and generate code coverage') {
                    agent { label NODE_LABELS }
                    steps {
                        gitlabCommitStatus(name: 'Swift Packages - Run Unit test and generate code coverage') {
                            withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                                script {
                                    envInjector.injectEnvs {
                                        setupProjectDependencies()
                                        sh "bundle exec fastlane run_tests_against_local_packages"
                                    }
                                }
                            }
                        }
                    }
                    post {
                        failure {
                            script {
                                envInjector.injectEnvs {
                                    dir("scripts/ErrorParsingKit/") {
                                        sh 'swift run'
                                    }
                                    if (fileExists('outputs/errors.md')) {
                                        sh 'cp outputs/errors.md outputs/errors_packages.md'
                                        artifactStasher.stashArtifact('swift-packages-errors', 'outputs/errors_packages.md')
                                    } else {
                                        echo "Warning: outputs/errors.md not found in Swift Packages run unit tests stage"
                                    } 
                                }
                            }
                        }
                        success {
                            script {
                                envInjector.injectEnvs {
                                    dir("scripts/CodeCoverageParserKit/") {
                                        sh 'swift run CodeCoverageParserKit --targets \"MEGAAppPresentation,MEGAAppSDKRepo,MEGAAuthentication,Chat,ChatRepo,Accounts,CloudDrive,ContentLibraries,DeviceCenter,MEGASwift,Notifications,Settings,MEGAAnalytics,MEGAAnalyticsDomain,MEGAConnectivity,MEGADeepLinkHandling,MEGADomain,MEGAFoundation,MEGAInfrastructure,MEGAIntentDomain,MEGAL10n,MEGALogger,MEGAPermissions,MEGAPhotos,MEGAPickerFileProviderDomain,MEGASwiftUI,MEGAUI,MEGAUIComponent,MEGAUIKit,PhotoBrowser,Search,Video\"'
                                    }

                                    if (fileExists('fastlane/code_coverage.md')) {
                                        sh 'cp fastlane/code_coverage.md fastlane/code_coverage_packages.md'
                                        artifactStasher.stashArtifact('swift-packages-coverage', 'fastlane/code_coverage_packages.md')
                                    } else {
                                        echo "Warning: fastlane/code_coverage.md not found in Swift Packages run unit tests stage"
                                    }                                
                                }
                            }
                        }
                        cleanup {
                            cleanWs(
                                cleanWhenFailure: true,
                                cleanWhenAborted: true,
                                cleanWhenNotBuilt: true,
                                cleanWhenUnstable: true,
                                cleanWhenSuccess: true,
                                disableDeferredWipeout: true,
                                deleteDirs: true
                            )
                        }
                    }
                }
            }
        }
    }
}
