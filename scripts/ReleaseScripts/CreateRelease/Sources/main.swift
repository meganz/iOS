import Foundation
import SharedReleaseScript

setVerbose()

do {
    log("Started execution")
    let version = if let cliVersion = parseVersionArg() {
        cliVersion
    } else if let version = try? VersionFetcher().fetchVersion() {
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

private func parseVersionArg() -> String? {
    let args = CommandLine.arguments
    guard let index = args.firstIndex(of: "--version"),
          index + 1 < args.count else { return nil }
    let version = args[index + 1]
    guard (try? matchesMajorMinorRelease(version)) == true else { return nil }
    return version
}

private func log(_ message: String) {
    print("CreateRelease script - \(message)")
}
