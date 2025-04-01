import ArgumentParser
import Foundation
import SharedReleaseScript

@main
struct App: AsyncParsableCommand {
    @Option(help: "Authorization token for the Transifex. Example: 'Bearer 1/0ab1234567a91c2f341d5c678e9012c3b4567ed8'")
    var transifexAuthorization: String

    @Option(help: "Resource ID to fetch the release notes from the transifex")
    var releaseNotesResourceID: String

    @Option(help: "Base URL for Gitlab.")
    var gitlabBaseURL: String

    @Option(help: "Gitlab token for the API.")
    var gitlabToken: String

    @Option(help: "Gitlab project ID.")
    var projectID: String

    @Option(help: "Branch from which the command is executed.")
    var branch: String

    func run() async throws {
        print("Fetching the current iOS app version.")
        let versionFetcher = VersionFetcher()
        let currentReleaseVersion = try versionFetcher.fetchVersion()
        print("Current version: \(currentReleaseVersion)")

        print("Fetching the SDK and Chat branch names")
        let sdkVersion = try tagOrBranchNameForSubmodule(with: Submodule.sdk.path)
        let chatSDKVersion = try tagOrBranchNameForSubmodule(with: Submodule.chatSDK.path)
        let sdkVersionFormatter = SDKVersionFormatter(sdkVersion: sdkVersion, chatSDKVersion: chatSDKVersion)
        print(sdkVersionFormatter.formatted())

        print("Fetching release notes for \(currentReleaseVersion)")
        let releaseNotes = try await fetchReleaseNotes(
            for: currentReleaseVersion,
            resourceID: releaseNotesResourceID,
            token: transifexAuthorization
        )
        print("release notes: \(releaseNotes)")

        let message = """
        \(releaseNotes)
        \(sdkVersionFormatter.formatted(prefix: "   -", plainText: true))
        """

        print("message is: \n \(message)")

        var branchName = branch
        if branchName.hasPrefix("origin/") {
            branchName = branchName.replacingOccurrences(of: "origin/", with: "", options: .anchored)
        }

        print("Creating Tag \(currentReleaseVersion)")
        try await TagManager.createTag(
            with: currentReleaseVersion,
            message: message,
            branch: branchName,
            gitlabBaseURL: gitlabBaseURL,
            gitlabToken: gitlabToken,
            projectID: projectID
        )
        print("Successfully created tag \(currentReleaseVersion)")

        print("Merging master => \(branch)")
        try mergeMasterWithOursStrategyAndPushToOrigin(currentBranch: branchName)
        print("successfully merging master => \(branch)")
    }
}
