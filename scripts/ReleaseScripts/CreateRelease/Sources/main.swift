import Foundation
import SharedReleaseScript

setVerbose()

do {
    log("Started execution")
    let version = if let version = readFromCache(key: .version) {
        version
    } else {
        try majorMinorInput("Enter the version number you're releasing (format: '[major].[minor]'):")
    }

    log("Creating release branch and pushing to origin")
    let releaseBranch = try createReleaseBranchAndPushToOrigin(version: version)

    log("Creating the release MR on GitLab")
    let gitlabMR = try await createMR(sourceBranch: releaseBranch, targetBranch: "master", title: "Release \(version)", squash: false)

    log("Commenting in MR to upload build to TestFlight")
    try await commentInMR(gitlabMR: gitlabMR, message: "deliver_appStore")

    log("Finished successfully")
    exit(ProcessResult.success)
} catch {
    exitWithError(error)
}

private func log(_ message: String) {
    print("CreateRelease script - \(message)")
}
