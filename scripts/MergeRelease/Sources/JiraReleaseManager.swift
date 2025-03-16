import Foundation
import SharedReleaseScript

struct JiraReleaseManager {
    struct JiraRelease: Decodable {
        let name: String
        let id: String
    }

    enum JiraError: Error {
        case noReleaseFound(version: String)
    }

    private static let decoder = JSONDecoder()

    static func markCurrentVersionAsReleasedInAllProjects(
        version: String,
        jiraProjects: String,
        jiraBaseURL: URL,
        jiraToken: String
    ) async throws {
        await withThrowingTaskGroup(of: Void.self) { group in
            for project in parseProjects(from: jiraProjects) {
                group.addTask {
                    try await markCurrentVersionAsReleasedInProject(
                        project: project,
                        version: version,
                        jiraBaseURL: jiraBaseURL,
                        jiraToken: jiraToken
                    )
                }
            }
        }
    }

    private static func markCurrentVersionAsReleasedInProject(
        project: JiraProject,
        version: String,
        jiraBaseURL: URL,
        jiraToken: String
    ) async throws {
        let releaseId = try await releaseId(
            projectId: project.id,
            version: version,
            jiraBaseURL: jiraBaseURL,
            jiraToken: jiraToken
        )
        let path = "/rest/api/2/version/\(releaseId)"
        let url = try makeURL(base: jiraBaseURL, path: path)

        let body: [String: Any] = [
            "id": releaseId,
            "project": project.name,
            "projectId": project.id,
            "releaseDate": iso8601Formatter.string(from: .now),
            "released": true
        ]

        try await sendRequest(
            url: url,
            method: .put,
            token: .bearer(jiraToken),
            headers: [
                .init(field: "Accept", value: "application/json"),
                .init(field: "Content-Type", value: "application/json")
            ],
            body: body
        )
    }

    private static func releaseId(
        projectId: Int64,
        version: String,
        jiraBaseURL: URL,
        jiraToken: String
    ) async throws -> String {
        let path = "/rest/api/2/project/\(projectId)/versions"
        let url = try makeURL(base: jiraBaseURL, path: path)
        let data = try await sendRequest(
            url: url,
            method: .get,
            token: .bearer(jiraToken),
            headers: [.init(field: "Accept", value: "application/json")]
        )

        let releases = try decoder.decode([JiraRelease].self, from: data)

        guard let release = releases.first(where: { $0.name == "iOS \(version)"}) else {
            throw JiraError.noReleaseFound(version: version)
        }

        return release.id
    }
}
