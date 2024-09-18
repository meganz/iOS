import Foundation
import SharedReleaseScript

setVerbose()

do {
    log("Started execution")
    let input = try releaseInput()

    let releaseBranch = "release/\(input.version)"

    log("Checking out to release branch and pull")
    try checkoutToReleaseAndPull(releaseBranch)

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
