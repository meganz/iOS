import groovy.transform.Field
@Library('jenkins-ios-shared-lib') _

// This is global variable is required to check if the unit test step was reached or not. This is required to avoid running the parse_and_upload_build_warnings_and_errors lane if the unit test step was not reached.
@Field boolean runUnitTestsStepReached = false

// Loaded jenkinsfile/package_tests.groovy. The stage and its post block share it.
@Field def packageTests = null

// Loaded jenkinsfile/benchmarks.groovy. The stage and its post block share it.
@Field def benchmarks = null

// Loaded jenkinsfile/snapshot_tests.groovy. The stage and its post block share it.
@Field def snapshotTests = null

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

// Writes outputs/errors.md for failed tests or build errors, and outputs/flaky_tests.md for flaky tests.
// A parser error is logged and never changes the build result.
def runErrorParsingKit(String arguments = '') {
    // No tests ran, so there is no xcresult to read.
    if (!fileExists('derivedData/Logs/Test')) {
        return
    }
    dir("scripts/ErrorParsingKit/") {
        def status = sh(script: "swift run ErrorParsingKit ${arguments}".trim(), returnStatus: true)
        if (status != 0) {
            echo "Warning: ErrorParsingKit failed with exit code ${status}"
        }
    }
}

def postFlakyTests() {
    // Report only. Any problem here is logged and never changes the build result.
    try {
        artifactStasher.unstashArtifact('swift-packages-flaky-tests')

        def mainAppFlakyTests = fileExists('outputs/flaky_tests.md') ?
                                    readFile('outputs/flaky_tests.md') : ''
        def packagesFlakyTests = fileExists('outputs/flaky_tests_packages.md') ?
                                    readFile('outputs/flaky_tests_packages.md') : ''
        if (!mainAppFlakyTests && !packagesFlakyTests) {
            return
        }
        def separator = (mainAppFlakyTests && packagesFlakyTests) ? '\n\n' : ''

        writeFile file: 'outputs/flaky_tests.md',
                 text: "${mainAppFlakyTests}${separator}${packagesFlakyTests}"

        executeFastlaneTask("post_flaky_tests", false)
    } catch (InterruptedException e) {
        throw e
    } catch (Exception e) {
        echo "Flaky tests report failed: ${e}"
    }
}

def postAppSizeToMR() {
    executeFastlaneTask("post_app_size_to_mr")
}

def postBenchmarkReportToMR() {
    // The report matters most when the benchmarks fail, so it does not wait for the unit test step.
    executeFastlaneTask("post_benchmark_report_to_mr", false)
}

def postL10nLintReportToMR() {
    // Report only. Any problem here is logged and never changes the build result.
    try {
        withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
            // This runs before setupProjectDependencies, so fastlane needs its gems here.
            sh "bundle install"
            def options = load('jenkinsfile/l10n_lint.groovy').runLocalizationCheck()
            if (options != null) {
                executeFastlaneTask("post_l10n_lint_report_to_mr ${options}".trim(), false)
            }
        }
    } catch (InterruptedException e) {
        throw e
    } catch (Exception e) {
        echo "Localization check failed: ${e}"
    }
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
                // ErrorParsingKit already ran in the always block, which runs before this block.
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
                    // Runs first, so an error in a later step cannot stop the error report of the failure block.
                    // A flaky test does not fail the build, so it is reported on success too.
                    runErrorParsingKit('--is-main-app-target true')
                    postFlakyTests()
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
                                        sh "bash scripts/print_ci_environment.sh"
                                        // Runs first so the MR comment arrives early without its own agent.
                                        postL10nLintReportToMR()
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
                                        sh "bash scripts/print_ci_environment.sh"
                                        setupProjectDependencies()
                                        packageTests = load('jenkinsfile/package_tests.groovy')
                                        packageTests.runPackageTests()
                                    }
                                }
                            }
                        }
                    }
                    post {
                        // Jenkins runs always before failure, so failure can read outputs/errors.md.
                        always {
                            script {
                                envInjector.injectEnvs {
                                    runErrorParsingKit()
                                    if (fileExists('outputs/flaky_tests.md')) {
                                        sh 'cp outputs/flaky_tests.md outputs/flaky_tests_packages.md'
                                        artifactStasher.stashArtifact('swift-packages-flaky-tests', 'outputs/flaky_tests_packages.md')
                                    }
                                }
                            }
                        }
                        failure {
                            script {
                                envInjector.injectEnvs {
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
                                    packageTests.reportPackageCoverage()
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
                stage('Benchmarks') {
                    agent { label NODE_LABELS }
                    steps {
                        gitlabCommitStatus(name: 'Benchmarks') {
                            withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                                script {
                                    envInjector.injectEnvs {
                                        sh "bash scripts/print_ci_environment.sh"
                                        benchmarks = load('jenkinsfile/benchmarks.groovy')
                                        benchmarks.runBenchmarks { setupProjectDependencies() }
                                    }
                                }
                            }
                        }
                    }
                    post {
                        always {
                            script {
                                envInjector.injectEnvs {
                                    if (benchmarks != null && benchmarks.publishResults()) {
                                        postBenchmarkReportToMR()
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
                stage('Snapshot tests') {
                    agent { label NODE_LABELS }
                    steps {
                        gitlabCommitStatus(name: 'Snapshot tests') {
                            withCredentials([gitUsernamePassword(credentialsId: 'Gitlab-Access-Token', gitToolName: 'Default')]) {
                                script {
                                    envInjector.injectEnvs {
                                        sh "bash scripts/print_ci_environment.sh"
                                        snapshotTests = load('jenkinsfile/snapshot_tests.groovy')
                                        snapshotTests.runSnapshotTests()
                                    }
                                }
                            }
                        }
                    }
                    post {
                        always {
                            script {
                                snapshotTests?.archiveSnapshotResults()
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
