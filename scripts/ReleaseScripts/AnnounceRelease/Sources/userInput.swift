import Foundation
import SharedReleaseScript

struct UserInput {
    let version: String
    let nextVersion: String
    let sdkVersion: String
    let chatVersion: String
    let releaseNotes: String
    let jiraReleasePackageLink: String
    let testFlightLink: String
}

func userInput() throws -> UserInput {
    let version = try majorMinorInput("Enter the version number you're releasing (format: '[major].[minor]'):")
    let nextVersion = try majorMinorInput("Enter the next release version number (format: '[major].[minor]'):")
    let sdkVersion = try majorMinorPatchInput(submoduleMessage(.sdk))
    let chatVersion = try majorMinorPatchInput(submoduleMessage(.chatSDK))
    let releaseNotes = try releaseNotesInput(defaultReleaseNotes: "Bug fixes and performance improvements.")
    let jiraReleasePackageLink = urlInput("Enter the Jira release package link for \(version) - (The one you created on 'Monday - Prepare Code Freeze'):")
    let testFlightLink = urlInput("Enter the TestFlight link for this build")
    return .init(
        version: version,
        nextVersion: nextVersion,
        sdkVersion: sdkVersion,
        chatVersion: chatVersion,
        releaseNotes: releaseNotes,
        jiraReleasePackageLink: jiraReleasePackageLink,
        testFlightLink: testFlightLink
    )
}

private func submoduleMessage(_ submodule: Submodule) -> String {
    "Enter the version number for \(submodule.description) (format: '[major].[minor].[patch]'):"
}
