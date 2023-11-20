import Foundation
import SharedReleaseScript

do {
    log("Started execution")

    log("Changing to root directory")
    try changeCurrentWorkDirectoryToRootDirectory()

    let userInput = try userInput()

    log("Creating hotfix \(userInput.hotfixVersion) from tag \(userInput.tag) (this might take a while)")
    try createHotfixBranchFromTag(userInput.tag, hotfixVersion: userInput.hotfixVersion)

    log("Finished successfully - go to Gitlab and open the hotfix branch MR against master")
    exit(ProcessResult.success)
} catch {
    exitWithError(error)
}

private func log(_ message: String) {
    print("PrepareHotfix script - \(message)")
}
