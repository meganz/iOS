import groovy.transform.Field

// Snapshot tests for the "Snapshot tests" stage in ios_build_status.groovy.
// Load it, then call runSnapshotTests() in the stage and archiveSnapshotResults() in post.always.

// A change under one of these paths can change every image, so it runs every snapshot package.
@Field final List<String> SHARED_PATHS = [
    'Modules/Infrastracture/MEGASnapshot/',
    'scripts/snapshot.sh',
    'jenkinsfile/snapshot_tests.groovy',
    'iMEGA.xcworkspace/xcshareddata/swiftpm/Package.resolved'
]

// MARK: - Stage entry points

def runSnapshotTests() {
    def packages = selectPackages()
    if (packages != null && packages.isEmpty()) {
        echo "No snapshot package is affected. Snapshot tests are skipped."
        return
    }
    sh "git submodule sync --recursive"
    sh "git submodule update --init --recursive"
    if (packages == null) {
        sh "scripts/snapshot.sh"
    } else {
        sh "scripts/snapshot.sh ${packages.join(' ')}"
    }
}

def archiveSnapshotResults() {
    archiveArtifacts(
        artifacts: 'derivedData/snapshots/*/xcodebuild.log, derivedData/snapshots/*/failures/**',
        allowEmptyArchive: true
    )
}

// MARK: - Selection

// Returns null for every package, or the snapshot packages that the MR diff touches.
// A change in a package's dependency does not select it. Builds of develop run every package.
def selectPackages() {
    if (env.BRANCH_NAME == 'develop') {
        return null
    }
    def mrNumber = commonUtils.getMRNumber()
    if (mrNumber == null || mrNumber.isEmpty()) {
        return null
    }
    // An explicit refspec updates origin/develop even when the checkout fetched only the MR branch.
    sh "git fetch --no-tags origin +refs/heads/develop:refs/remotes/origin/develop"
    def changed = lines(sh(returnStdout: true, script: "git diff --name-only origin/develop...HEAD"))
    for (path in changed) {
        for (shared in SHARED_PATHS) {
            if (path.startsWith(shared)) {
                return null
            }
        }
    }

    def snapshotPackages = lines(sh(
        returnStdout: true,
        script: 'for d in Modules/*/*/; do n=$(basename "$d"); if [ -d "$d/Tests/${n}SnapshotTests" ]; then echo "${d%/}"; fi; done'
    ))
    def selected = []
    for (snapshotPackage in snapshotPackages) {
        for (path in changed) {
            if (path.startsWith(snapshotPackage + '/')) {
                selected << snapshotPackage
                break
            }
        }
    }
    return selected
}

def lines(String text) {
    def result = []
    for (line in text.split('\n')) {
        if (!line.trim().isEmpty()) {
            result << line.trim()
        }
    }
    return result
}

return this
