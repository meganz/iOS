import groovy.transform.Field

// Benchmarks for the "Benchmarks" stage in ios_build_status.groovy.
// Load it, call runBenchmarks() in the stage, then publishResults() in post.always.
// A package opts in with Tests/<package>Benchmarks/Limits.json. See Modules/Infrastracture/MEGABenchmark/README.md.

@Field final String PACKAGES_FILE = 'benchmark_packages.txt'
@Field final String REPORT_FILE = 'outputs/benchmarks.md'
@Field final String OUTPUT_ROOT = 'derivedData/benchmarks'
// Limits.json is recorded on this simulator. The CI package tests use the same model.
@Field final String SIMULATOR_NAME = 'iPhone 17 Pro'
@Field final String SIMULATOR_OS = '26.4'

@Field List packages = []

// MARK: - Stage entry points

// setup prepares the workspace. It runs only when at least one package is selected.
def runBenchmarks(Closure setup) {
    packages = selectPackages()
    if (packages.isEmpty()) {
        echo "No benchmark package is affected. Benchmarks are skipped."
        return
    }
    setup()

    def failed = []
    def report = "## Benchmarks\n\nSimulator: ${SIMULATOR_NAME}, iOS ${SIMULATOR_OS}.\n\n"
    for (packagePath in packages) {
        def name = packagePath.tokenize('/').last()
        def output = "${OUTPUT_ROOT}/ci-${name}"
        def status = sh(
            returnStatus: true,
            script: "scripts/benchmark.sh '${packagePath}' --sim-name '${SIMULATOR_NAME}' --sim-os ${SIMULATOR_OS} --out '${output}'"
        )
        def packageReport = fileExists("${output}/report.md") ? readFile("${output}/report.md") : "No report. See the build log.\n"
        report += "### ${name}\n\n${packageReport}\n"
        if (status != 0) {
            failed << name
        }
    }
    if (!failed.isEmpty()) {
        report += "\nTo unblock an MR, list the test with a reason in `Tests/<package>Benchmarks/Skipped.json`.\n"
    }
    sh "mkdir -p outputs"
    writeFile file: REPORT_FILE, text: report

    if (!failed.isEmpty()) {
        error("Benchmarks failed: ${failed.join(', ')}")
    }
}

// Archives the run output. Returns true when there is a report to post to the MR.
def publishResults() {
    if (packages.isEmpty()) {
        return false
    }
    sh "for folder in ${OUTPUT_ROOT}/ci-*; do [ -d \"\$folder/result.xcresult\" ] && (cd \"\$folder\" && zip -qry result.xcresult.zip result.xcresult); done; true"
    archiveArtifacts(
        artifacts: "${OUTPUT_ROOT}/ci-*/report.md, ${OUTPUT_ROOT}/ci-*/metrics.json, ${OUTPUT_ROOT}/ci-*/manifest.json, " +
            "${OUTPUT_ROOT}/ci-*/xcodebuild.log, ${OUTPUT_ROOT}/ci-*/result.xcresult.zip",
        allowEmptyArchive: true
    )
    return fileExists(REPORT_FILE)
}

// MARK: - Selection. A selector problem runs every opted-in package.

def selectPackages() {
    def mode = '--all'
    if (env.BRANCH_NAME != 'develop') {
        def mrNumber = null
        try {
            mrNumber = commonUtils.getMRNumber()
        } catch (InterruptedException e) {
            throw e
        } catch (Exception e) {
            echo "Could not read the MR number: ${e}"
        }
        if (mrNumber != null && !mrNumber.isEmpty()) {
            // An explicit refspec updates origin/develop even when the checkout fetched only the MR branch.
            sh "git fetch --no-tags origin +refs/heads/develop:refs/remotes/origin/develop"
            mode = '--base origin/develop'
        }
    }
    def status = sh(returnStatus: true, script: "python3 scripts/benchmark_ci.py packages --repo-root . ${mode} --output ${PACKAGES_FILE}")
    if (status != 0 && mode != '--all') {
        echo "Benchmark package selection failed. Every opted-in package runs."
        status = sh(returnStatus: true, script: "python3 scripts/benchmark_ci.py packages --repo-root . --all --output ${PACKAGES_FILE}")
    }
    if (status != 0) {
        error("Could not list the benchmark packages")
    }
    return readFile(PACKAGES_FILE).split('\n').collect { it.trim() }.findAll { !it.isEmpty() }
}

return this
