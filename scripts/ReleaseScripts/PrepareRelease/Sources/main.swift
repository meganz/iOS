import Foundation
import SharedReleaseScript

setVerbose()

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
    let prepareBranch = try createPrepareBranch(userInput.version)

    log("Performing Transifex operations: pruning (this might take a while)")
    try pruneTransifexStrings()

    log("Performing Transifex operations: downloading resources (this might take a while)")
    try downloadTransifexResources()

    log("Updating project version to \(userInput.version)")
    try updateProjectVersion(userInput.version)

    log("Fetching origin for git submodules")
    try fetchOriginForSubmodules()

    log("Updating git submodule \(Submodule.sdk.description)")
    try updateSubmodule(submodule: .sdk)

    log("Updating git submodule \(Submodule.chatSDK.description)")
    try updateSubmodule(submodule: .chatSDK)

    log("Checking out \(Submodule.sdk.description) to \(userInput.sdkHash)")
    try checkoutSubmoduleToCommit(submodule: .sdk, commitHash: userInput.sdkHash)

    log("Checking out \(Submodule.chatSDK.description) to \(userInput.chatHash)")
    try checkoutSubmoduleToCommit(submodule: .chatSDK, commitHash: userInput.chatHash)

    log("Creating prepare branch commit")
    try createReleaseCommit(version: userInput.version, prepareBranch: prepareBranch)

    log("Pushing the branch to GitLab and creating the prepare MR")
    try createMRUsingGitCommand(
        sourceBranch: prepareBranch,
        targetBranch: "develop",
        title: "Prepare v\(userInput.version)",
        squash: true
    )

    log("Finished successfully")
    exit(ProcessResult.success)
} catch {
    exitWithError(error)
}

private func log(_ message: String) {
    print("PrepareRelease script - \(message)")
}
