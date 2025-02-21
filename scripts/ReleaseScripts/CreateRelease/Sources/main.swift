import Foundation
import SharedReleaseScript

setVerbose()

do {
    log("Started execution")
    let version = if let version = try? VersionFetcher().fetchVersion() {
        version
    } else {
        try majorMinorInput("Enter the version number you're releasing (format: '[major].[minor]'):")
    }

    log("Creating release branch")
    let releaseBranch = try createReleaseBranch(with: version)

    log("Push the changes and create the release MR on GitLab")
    try createMRUsingGitCommand(
        sourceBranch: releaseBranch,
        targetBranch: "master",
        title: "Release \(version)",
        squash: false
    )

    log("Finished successfully")
    exit(ProcessResult.success)
} catch {
    exitWithError(error)
}

private func log(_ message: String) {
    print("CreateRelease script - \(message)")
}
