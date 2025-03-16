import Foundation
import SharedReleaseScript

struct ReleaseBranchManager {
    enum GitlabError: Error {
        case releaseMRNotFound
        case invalidURL(String)
    }

    private static let decoder = JSONDecoder()

    static func mergeReleaseMR(_ version: String, gitlabBaseURL: URL, gitlabToken: String, projectID: String) async throws {
        let mergeRequests = try await openMRs(
            gitlabBaseURL: gitlabBaseURL,
            gitlabToken: gitlabToken,
            projectID: projectID
        )

        let releaseMR = mergeRequests.first(
            where: {
                let sanitizedTitle = $0.title.lowercased()
                return (
                    sanitizedTitle.contains("release") || sanitizedTitle.contains("hotfix")
                ) && sanitizedTitle.contains(version)
            }
        )

        guard let releaseMR else {
            throw GitlabError.releaseMRNotFound
        }
        
        let url = try makeURL(string: "\(gitlabBaseURL)/projects/\(projectID)/merge_requests/\(releaseMR.iid)/merge?should_remove_source_branch=true&squash=false")
        try await sendRequest(url: url, method: .put, token: .bearer(gitlabToken))
    }

    static func createRelease(
        with version: String,
        message: String,
        gitlabBaseURL: URL,
        gitlabToken: String,
        projectID: String
    ) async throws {
        let url = try makeURL(string: "\(gitlabBaseURL)/projects/\(projectID)/releases?name=\(version)&tag_name=\(version)&description=\(message)")
        try await sendRequest(url: url, method: .post, token: .bearer(gitlabToken))
    }

    static private func openMRs(
        gitlabBaseURL: URL,
        gitlabToken: String,
        projectID: String
    ) async throws -> [GitlabMR] {
        let url = try makeURL(string: "\(gitlabBaseURL)/projects/\(projectID)/merge_requests?state=opened")
        let data = try await sendRequest(url: url, method: .get, token: .bearer(gitlabToken))
        return try decoder.decode([GitlabMR].self, from: data)
    }
}
