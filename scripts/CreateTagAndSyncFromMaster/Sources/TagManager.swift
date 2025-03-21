import Foundation
import SharedReleaseScript

struct TagManager {
    static func createTag(
        with name: String,
        message: String,
        branch: String,
        gitlabBaseURL: String,
        gitlabToken: String,
        projectID: String
    ) async throws {
        let urlString = "\(gitlabBaseURL)/projects/\(projectID)/repository/tags?tag_name=\(name)&message=\(message)&ref=\(branch)"
        let url = try makeURL(string: urlString)
        try await sendRequest(url: url, method: .post, token: .bearer(gitlabToken))
    }
}
