do {
    log("Started execution")

    log("Changing to root directory")
    try changeCurrentWorkDirectoryToRootDirectory()

    let userInput = try userInput()

    log(
    """
    Creating prepare branch for \(userInput.version)
    \(Submodule.sdk.description) release commit: \(userInput.sdkHash)
    \(Submodule.chatSDK.description) release commit: \(userInput.chatHash)
    """
    )
    try createPrepareBranch(userInput.version)

    log("Performing Transifex operations: pruning (this might take a while)")
    try pruneTransifexStrings()

    log("Performing Transifex operations: downloading resources (this might take a while)")
    try downloadTransifexResources()

    log("Updating project version to \(userInput.version)")
    try updateProjectVersion(userInput.version)
    
    log("Checking out \(Submodule.sdk.description) to \(userInput.sdkHash)")
    try checkoutSubmoduleToCommit(submodule: .sdk, commitHash: userInput.sdkHash)

    log("Checking out \(Submodule.chatSDK.description) to \(userInput.chatHash)")
    try checkoutSubmoduleToCommit(submodule: .chatSDK, commitHash: userInput.chatHash)

    log("Creating prepare branch commit and pushing the branch to GitLab")
    try createReleaseCommitAndPushToOrigin(userInput.version)

    log("Finished successfully - go to Gitlab and open the prepare branch MR")
    exit(ProcessResult.success)
} catch {
    exitWithError(error)
}

private func exitWithError(_ error: Error) -> Never {
    let prefix = "finished with error\n"

    if let shellError = error as? ShellError {
        log("\(prefix)Shell error: \(shellError.description)")
        exit(shellError.code)
    } else {
        log("\(prefix)Error: \(String(describing: error))\n description: \(error.localizedDescription)")
        exit(ProcessResult.error)
    }
}

private func log(_ message: String) {
    print("PrepareRelease script - \(message)")
}
