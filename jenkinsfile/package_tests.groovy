import groovy.transform.Field

// Package tests for the "Swift Packages" stage in ios_build_status.groovy.
// Load it, then call runPackageTests() in the stage and reportPackageCoverage() in post.success.

@Field final String SELECTION_FILE = 'package_test_selection.txt'
@Field final String SELECTOR_STDERR_FILE = 'package_test_selector_stderr.txt'
@Field final String TEST_PLAN = 'MEGAModulesTests/MEGAModulesTests.xctestplan'
@Field final String COVERAGE_FILE = 'fastlane/code_coverage_packages.md'
// Used only when the selector fails. Normally the selector builds the coverage list from Package.swift.
@Field final String DEFAULT_COVERAGE_TARGETS = 'MEGAAppPresentation,MEGAAppSDKRepo,MEGAAuthentication,MEGABenchmark,Chat,ChatRepo,Accounts,CloudDrive,ContentLibraries,DeviceCenter,MEGASwift,Notifications,Settings,MEGAAnalytics,MEGAAnalyticsDomain,MEGAConnectivity,MEGADeeplinkHandling,MEGADomain,MEGAFoundation,MEGAInfrastructure,MEGAIntentDomain,MEGAL10n,MEGALogger,MEGAMarkdown,MEGAMarkdownEditor,MEGATextEditor,MEGAPermissions,MEGAPhotos,MEGAPickerFileProviderDomain,MEGASwiftUI,MEGAUI,MEGAUIComponent,MEGAUIKit,PhotosBrowser,Search,Video'

// [tests: 'ALL' | 'NONE' | comma list of test targets, coverage: comma list or '', reason: text]
@Field Map selection = [tests: 'ALL', coverage: '', reason: 'not selected yet']

// MARK: - Stage entry points

def runPackageTests() {
    selection = selectPackageTests()
    echo "Package test selection: ${selection.tests} (${selection.reason})"

    if (selection.tests == 'NONE') {
        echo "No package is affected. Package tests are skipped."
    } else if (selection.tests == 'ALL') {
        sh "bundle exec fastlane run_tests_against_local_packages"
    } else {
        sh "bundle exec fastlane run_tests_against_local_packages only_testing:${selection.tests}"
    }
}

def reportPackageCoverage() {
    if (selection.tests == 'NONE') {
        // No tests ran, so there is no xcresult. The top-level success block still unstashes this.
        writeFile file: COVERAGE_FILE, text: ''
        artifactStasher.stashArtifact('swift-packages-coverage', COVERAGE_FILE)
        return
    }

    def coverageTargets = selection.coverage.isEmpty() ? DEFAULT_COVERAGE_TARGETS : selection.coverage
    dir("scripts/CodeCoverageParserKit/") {
        sh "swift run CodeCoverageParserKit --targets \"${coverageTargets}\""
    }

    if (fileExists('fastlane/code_coverage.md')) {
        sh "cp fastlane/code_coverage.md ${COVERAGE_FILE}"
        artifactStasher.stashArtifact('swift-packages-coverage', COVERAGE_FILE)
    } else {
        echo "Warning: fastlane/code_coverage.md not found in Swift Packages run unit tests stage"
    }
}

// MARK: - Selection. Any problem falls back to the full suite.

def selectPackageTests() {
    // The selector still runs for a full suite. It gives the coverage list.
    if (env.BRANCH_NAME == 'develop') {
        return runSelector("--all develop")
    }
    def mrNumber = null
    try {
        mrNumber = commonUtils.getMRNumber()
    } catch (InterruptedException e) {
        throw e
    } catch (Exception e) {
        echo "Could not read the MR number: ${e}"
    }
    if (mrNumber == null || mrNumber.isEmpty()) {
        return runSelector("--all 'no MR'")
    }
    return runSelector("--base origin/develop")
}

def fullSuite(String reason) {
    return [tests: 'ALL', coverage: '', reason: reason]
}

// modeArguments: "--base origin/develop" to select by the MR diff, or "--all <reason>" for the full suite.
def runSelector(String modeArguments) {
    def status = 1
    def failure = ''
    try {
        if (modeArguments.startsWith('--base')) {
            // An explicit refspec updates origin/develop even when the checkout fetched only the MR branch.
            sh "git fetch --no-tags origin +refs/heads/develop:refs/remotes/origin/develop"
        }
        status = sh(
            returnStatus: true,
            script: "swift run --quiet --package-path scripts/TestSelectorKit TestSelectorKit --repo-root . ${modeArguments} " +
                "--test-plan ${TEST_PLAN} --output ${SELECTION_FILE} 2> ${SELECTOR_STDERR_FILE}"
        )
    } catch (InterruptedException e) {
        // An abort or timeout must stop the build, not fall back to the full suite.
        throw e
    } catch (Exception e) {
        failure = e.toString()
    }

    if (status != 0) {
        if (failure.isEmpty() && fileExists(SELECTOR_STDERR_FILE)) {
            failure = sh(returnStdout: true, script: "head -n 20 ${SELECTOR_STDERR_FILE}").trim()
        }
        return fullSuite("selector failed: ${failure}")
    }
    if (!fileExists(SELECTION_FILE)) {
        return fullSuite('selector failed: no output file')
    }
    return readSelection()
}

def readSelection() {
    def lines = readFile(SELECTION_FILE).split('\n', -1)
    def tests = lines.size() > 0 ? lines[0].trim() : ''
    def coverage = lines.size() > 1 ? lines[1].trim() : ''
    def reason = lines.size() > 2 ? lines[2].trim() : ''

    def validCoverage = (coverage ==~ /[A-Za-z0-9_,]*/) ? coverage : ''
    if (tests == 'ALL') {
        return [tests: 'ALL', coverage: validCoverage, reason: reason]
    }
    if (tests == 'NONE') {
        return [tests: 'NONE', coverage: '', reason: reason]
    }
    if (!(tests ==~ /[A-Za-z0-9_]+(,[A-Za-z0-9_]+)*/)) {
        return fullSuite("invalid output: ${tests}")
    }
    // A wrong -only-testing name passes with 0 tests, so every name must be in the test plan.
    def testPlan = readFile(TEST_PLAN)
    for (name in tests.split(',')) {
        if (!testPlan.contains("\"name\" : \"${name}\"")) {
            return fullSuite("unknown target ${name}")
        }
    }
    return [tests: tests, coverage: validCoverage, reason: reason]
}

return this
