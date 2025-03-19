import Foundation
import SharedReleaseScript

setVerbose()

do {
    log("Started execution")

    log("Changing to root directory")
    try changeCurrentWorkDirectoryToRootDirectory()

    let userInput = try userInput()

    log("Creating hotfix \(userInput.hotfixVersion) from tag \(userInput.tag) (this might take a while)")
    let branchName = try createHotfixBranchFromTag(userInput.tag, hotfixVersion: userInput.hotfixVersion)

    log("Creating hotfix MR on GitLab")
    try createMRUsingGitCommand(
        sourceBranch: branchName,
        targetBranch: "master",
        title: "Hotfix \(userInput.hotfixVersion)",
        squash: false
    )

    log("Finished successfully")
    exit(ProcessResult.success)
} catch {
    exitWithError(error)
}

private func log(_ message: String) {
    print("PrepareHotfix script - \(message)")
}
