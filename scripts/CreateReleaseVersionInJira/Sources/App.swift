import ArgumentParser
import Foundation
import SharedReleaseScript

@main
struct App: AsyncParsableCommand {
    @Option(help: "Base URL for Jira")
    var jiraBaseURLString: String

    @Option(help: "projects separated by comma. Example: IOS:1,Android:2,WEB:3")
    var jiraProjects: String

    @Option(help: "Authorization token for the Jira. Example: '0ab1234567a91c2f341d5c678e9012c3b4567ed8'")
    var jiraAuthorization: String

    func run() async throws {
        guard let jiraBaseURL = URL(string: jiraBaseURLString) else {
            fatalError("Invalid Gitlab Base URL: \(jiraBaseURLString)")
        }

        let version = try VersionFetcher().fetchVersion()

        print("Creating release version iOS \(version) for all Main Application Jira projects")
        try await createReleaseVersion(
            version: version,
            jiraBaseURL: jiraBaseURL,
            jiraToken: jiraAuthorization,
            jiraProjects: jiraProjects
        )
        print("creating release version done.")
    }
}
