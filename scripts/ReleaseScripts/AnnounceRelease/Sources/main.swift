import Foundation
import SharedReleaseScript

setVerbose()

do {
    log("Started execution")
    let input = try userInput()

    log("Creating release version iOS \(input.nextVersion) for all Main Application Jira projects")
    try await createReleaseVersion(version: input.nextVersion)

    log("Sending release candidate message to Slack")
    try await sendReleaseCandidateMessage(input: input)

    log("Sending code freeze reminder message to Slack")
    try await sendCodeFreezeReminderMessage(version: input.version, nextVersion: input.nextVersion)

    log("Finished successfully")
    exit(ProcessResult.success)
} catch {
    exitWithError(error)
}

private func log(_ message: String) {
    print("AnnounceReleaseScript - \(message)")
}
