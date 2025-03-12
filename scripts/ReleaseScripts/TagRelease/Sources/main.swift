import Foundation
import SharedReleaseScript

setVerbose()

do {
    log("Started execution")

    log("Pull latest changes")
    try pullLatestChanges()

    log("Get the version and the message")
    let input = try releaseInput()
    let releaseBranch = try runInShell("git branch --show-current")

    log("Creating tag and pushing to origin")
    try createTagAndPushToOrigin(version: input.version, message: input.message)

    log("Checking out to master and pulling")
    try checkoutToMasterAndPull()

    log("Checking out to release branch and pull")
    try checkoutToReleaseAndPull(releaseBranch)

    log("Merging master into \(releaseBranch) using -s ours strategy and pushing to origin")
    try mergeMasterWithOursStrategyAndPushToOrigin()

    log("Finished successfully")
    exit(ProcessResult.success)
} catch {
    exitWithError(error)
}

private func log(_ message: String) {
    print("TagRelease script - \(message)")
}
