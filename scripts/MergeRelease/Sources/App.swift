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

    @Option(help: "Base URL for Jira")
    var jiraBaseURLString: String

    @Option(help: "Authorization token for the Jira. Example: '0ab1234567a91c2f341d5c678e9012c3b4567ed8'")
    var jiraAuthorization: String

    @Option(help: "projects separated by comma. Example: IOS:1,Android:2,WEB:3")
    var jiraProjects: String

    @Option(help: "Github access token.")
    var githubAccessToken: String

    @Option(help: "Gitlab project ID.")
    var projectID: String

    func run() async throws {
        guard let gitlabBaseURL = URL(string: gitlabBaseURL) else {
            fatalError("Invalid Gitlab Base URL: \(gitlabBaseURL)")
        }

        guard let jiraBaseURL = URL(string: jiraBaseURLString) else {
            fatalError("Invalid Jira Base URL: \(jiraBaseURLString)")
        }

        print("Fetching the current iOS app version.")
        let versionFetcher = VersionFetcher()
        let version = try versionFetcher.fetchVersion()
        print("Current version: \(version)")

        print("Fetching the SDK and Chat branch names")
        let sdkVersion = try tagOrBranchNameForSubmodule(with: Submodule.sdk.path)
        let chatSDKVersion = try tagOrBranchNameForSubmodule(with: Submodule.chatSDK.path)
        print("""
        - \(sdkVersion.description(type: "SDK"))
        - \(chatSDKVersion.description(type: "Chat SDK"))
        """)

        print("Fetching release notes for \(version)")
        let releaseNotes = try await fetchReleaseNotes(
            for: version,
            resourceID: releaseNotesResourceID,
            token: transifexAuthorization
        )
        print("release notes: \(releaseNotes)")

        print("Merge the branch.")
        try await ReleaseBranchManager
            .mergeReleaseMR(version, gitlabBaseURL: gitlabBaseURL, gitlabToken: gitlabToken, projectID: projectID)
        print("Merge the branch completed.")

        let message = """
        \(releaseNotes)
        - \(sdkVersion.description(type: "SDK"))
        - \(chatSDKVersion.description(type: "Chat SDK"))
        """

        print("Creating release in Gitlab")
        try await ReleaseBranchManager
            .createRelease(
                with: version,
                message: message,
                gitlabBaseURL: gitlabBaseURL,
                gitlabToken: gitlabToken,
                projectID: projectID
            )
        print("Creating release in Gitlab completed.")

        print("Marking version \(version) as released in Jira projects")
        try await JiraReleaseManager
            .markCurrentVersionAsReleasedInAllProjects(
                version: version,
                jiraProjects: jiraProjects,
                jiraBaseURL: jiraBaseURL,
                jiraToken: jiraAuthorization
            )
        print("Marking version \(version) as released in Jira projects completed")

        print("Pushing master to GitHub")
        try await GithubManager
            .pushMasterToPublicAndCreateRelease(
                for: version,
                githubAccessToken: githubAccessToken,
                message: message
            )
        print("Pushing master to GitHub completed.")
    }
}
