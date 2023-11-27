import Foundation
import SharedReleaseScript

enum JiraError: Error {
    case noReleaseFound(version: String)
}

struct JiraRelease: Decodable {
    let name: String
    let id: String
}

func markCurrentVersionAsReleasedInAllProjects(version: String) async throws {
    // Mark version as released concurrently in all projects
    await withThrowingTaskGroup(of: Void.self) { group in
        for project in environment.jiraProjects {
            group.addTask {
                try await markCurrentVersionAsReleasedInProject(project: project, version: version)
            }
        }
    }
}

private func markCurrentVersionAsReleasedInProject(project: JiraProject, version: String) async throws {
    let releaseId = try await releaseId(projectId: project.id, version: version)
    let path = "/rest/api/2/version/\(releaseId)"
    let url = makeURL(base: environment.jiraBaseURL, path: path)

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
        token: .bearer(environment.jiraToken),
        headers: [
            .init(field: "Accept", value: "application/json"),
            .init(field: "Content-Type", value: "application/json")
        ],
        body: body
    )
}

private let decoder = JSONDecoder()

private func releaseId(projectId: Int64, version: String) async throws -> String {
    let path = "/rest/api/2/project/\(projectId)/versions"
    let url = makeURL(base: environment.jiraBaseURL, path: path)
    let data = try await sendRequest(
        url: url,
        method: .get,
        token: .bearer(environment.jiraToken),
        headers: [.init(field: "Accept", value: "application/json")]
    )

    let releases = try decoder.decode([JiraRelease].self, from: data)

    guard let release = releases.first(where: { $0.name == "iOS \(version)"}) else {
        throw JiraError.noReleaseFound(version: version)
    }

    return release.id
}
