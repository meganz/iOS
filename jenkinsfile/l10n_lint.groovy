import groovy.transform.Field

// Localization check for MR builds. ios_build_status.groovy runs it at the start of the
// main app stage.
// It lints only the Localizable keys that the MR changed and writes outputs/l10n_lint.md.
// Report only: a problem or a crash never changes the build result.

@Field final String RESOURCES = 'Modules/Presentation/MEGAL10n/Framework/MEGAL10n/MEGAL10n/Resources'
@Field final String REPORT_FILE = 'outputs/l10n_lint.md'
@Field final String JSON_FILE = 'outputs/l10n_lint.json'
@Field final String STDERR_FILE = 'outputs/l10n_lint.stderr'

// Writes REPORT_FILE. Returns the extra fastlane options for the post, or null when this
// build is not for an MR. 'update_only:true' means: update an earlier comment, add none.
def runLocalizationCheck() {
    def mrNumber = commonUtils.getMRNumber()
    if (mrNumber == null || mrNumber.isEmpty()) {
        return null
    }
    // An explicit refspec updates origin/develop even when the checkout fetched only the MR branch.
    sh "git fetch --no-tags origin +refs/heads/develop:refs/remotes/origin/develop"
    sh "mkdir -p outputs"

    def files = "'${RESOURCES}/*.lproj/Localizable.strings' '${RESOURCES}/*.lproj/Localizable.stringsdict'"
    def changed = sh(returnStatus: true, script: "git diff --quiet \$(git merge-base origin/develop HEAD) HEAD -- ${files}") != 0

    def reportUrl = "${env.BUILD_URL}artifact/${JSON_FILE}"
    def status = sh(
        returnStatus: true,
        script: "python3 scripts/l10n_lint.py --root '${RESOURCES}' --changed-since origin/develop " +
            "--min-severity warning --fail-on never --format mr-markdown --output ${REPORT_FILE} " +
            "--json-output ${JSON_FILE} --report-url '${reportUrl}' 2> ${STDERR_FILE}"
    )
    def stderr = fileExists(STDERR_FILE) ? readFile(STDERR_FILE).trim() : ''
    echo "l10n_lint exit code ${status}\n${stderr}"
    if (status != 0) {
        def firstLine = stderr ? stderr.readLines().first().replace('`', "'") : 'no output'
        writeFile file: REPORT_FILE, text: "<!-- l10n-lint -->\n" +
            "#### :warning: Localization check did not run\n" +
            "`l10n_lint.py` stopped with exit code ${status}:\n" +
            "`${firstLine}`\n" +
            "See the [build log](${env.BUILD_URL}console). This does not block the merge.\n"
    }
    archiveArtifacts(artifacts: "${JSON_FILE}, ${STDERR_FILE}", allowEmptyArchive: true)
    return changed ? '' : 'update_only:true'
}

return this
