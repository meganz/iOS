import SharedReleaseScript

setVerbose()

do {
    log("Started execution")
    let userInput = try userInput()

    let releaseBranch = "release/\(userInput.version)"

    log("Checking out to release branch and pull")
    try checkoutToReleaseAndPull(releaseBranch)

    log("Creating tag and pushing to origin")
    try createTagAndPushToOrigin(version: userInput.version, message: userInput.message)

    log("Checking out to master and pulling")
    try checkoutToMasterAndPull()

    log("Checking out to release branch and pull")
    try checkoutToReleaseAndPull(releaseBranch)

    log("Merging master into \(releaseBranch) using -s ours strategy and pushing to origin")
    try mergeMasterWithOursStrategyAndPushToOrigin()

    log("Merging \(releaseBranch) into master")
    try await mergeReleaseMR(userInput.version)

    log("Creating release in Gitlab")
    try await createRelease(userInput)

    log("Marking version \(userInput.version) as released in Jira projects")
    try await markCurrentVersionAsReleasedInAllProjects(version: userInput.version)

    log("Pushing master to GitHub")
    try pushToPublicMaster(userInput.version)

    log("Finished successfully")
    exit(ProcessResult.success)
} catch {
    exitWithError(error)
}

private func log(_ message: String) {
    print("TagRelease script - \(message)")
}
