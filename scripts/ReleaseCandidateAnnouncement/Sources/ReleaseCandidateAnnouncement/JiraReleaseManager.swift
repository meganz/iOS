import Foundation
import SharedReleaseScript

struct JiraReleaseManager {
    private struct JiraProject: Decodable {
        public let name: String
        public let id: Int64
    }

    public static func createReleaseVersion(
        version: String,
        jiraBaseURL: URL,
        jiraToken: String,
        jiraProjects: String
    ) async throws {
        let releasePath = "/rest/api/2/version"
        let url = try makeURL(base: jiraBaseURL, path: releasePath)

        let jiraProjects = parseProjects(from: jiraProjects)

        await withTaskGroup(of: Void.self) { group in
            for project in jiraProjects {
                group.addTask {
                    do {
                        try await createReleaseVersion(project: project, version: version, jiraURL: url, jiraToken: jiraToken)
                    } catch {
                        print(
                            "Creating release version iOS \(version) for jira project \(project.name) Failed: \(error)"
                        )
                    }
                }
            }
        }
    }

    private static func createReleaseVersion(project: JiraProject, version: String, jiraURL: URL, jiraToken: String) async throws {
        let body: [String: Any] = [
            "name": "iOS \(version)",
            "project": project.name,
            "projectId": project.id,
            "startDate": iso8601Formatter.string(from: .now)
        ]

        try await sendRequest(
            url: jiraURL,
            method: .post,
            token: .bearer(jiraToken),
            headers: [.init(field: "Content-Type", value: "application/json")],
            body: body
        )
    }
}
