import Foundation
import SharedReleaseScript

enum GitlabError: Error {
    case releaseMRNotFound
}

func createRelease(_ input: UserInput) async throws {
    let url = try makeURL(
        base: environment.gitlabBaseURL,
        path: "/api/v4/projects/\(environment.gitlabProjectId)/releases",
        queryItems: [
            .init(name: "name", value: input.version),
            .init(name: "tag_name", value: input.version),
            .init(name: "description", value: input.message)
        ]
    )

    try await sendRequest(url: url, method: .post, token: .bearer(environment.gitlabToken))
}

func mergeReleaseMR(_ version: String) async throws {
    let mergeRequests = try await openMRs()

    let releaseMR = mergeRequests.first(where: {
        let sanitizedTitle = $0.title.lowercased()
        return sanitizedTitle.contains("release") && sanitizedTitle.contains(version)
    })

    guard let releaseMR else {
        throw GitlabError.releaseMRNotFound
    }

    let url = try makeURL(
        base: environment.gitlabBaseURL,
        path: "/api/v4/projects/\(environment.gitlabProjectId)/merge_requests/\(releaseMR.iid)/merge",
        queryItems: [
            .init(name: "should_remove_source_branch", value: "true"),
            .init(name: "squash", value: "false")
        ]
    )

    try await sendRequest(url: url, method: .put, token: .bearer(environment.gitlabToken))
}

private let decoder = JSONDecoder()

private func openMRs() async throws -> [GitlabMR] {
    let url = try makeURL(
        base: environment.gitlabBaseURL,
        path: "/api/v4/projects/\(environment.gitlabProjectId)/merge_requests",
        queryItems: [
            .init(name: "state", value: "opened")
        ]
    )

    let data = try await sendRequest(url: url, method: .get, token: .bearer(environment.gitlabToken))

    return try decoder.decode([GitlabMR].self, from: data)
}
