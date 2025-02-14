import Foundation

public struct GitlabMR: Decodable {
    public let title: String
    // 'iid' stands for "Internal Id" in GitLab's API: https://docs.gitlab.com/ee/api/rest/#id-vs-iid
    public let iid: Int
}

@discardableResult
public func createMR(
    sourceBranch: String,
    targetBranch: String,
    title: String,
    squash: Bool
) async throws -> GitlabMR {
    let url = try makeURL(
        base: environment.gitlabBaseURL,
        path: "/api/v4/projects/\(environment.gitlabProjectId)/merge_requests",
        queryItems: [
            .init(name: "source_branch", value: sourceBranch),
            .init(name: "target_branch", value: targetBranch),
            .init(name: "title", value: title),
            .init(name: "squash", value: .init(describing: squash)),
            .init(name: "remove_source_branch", value: "true")
        ]
    )

    let data = try await sendRequest(url: url, method: .post, token: .bearer(environment.gitlabToken))

    return try decoder.decode(GitlabMR.self, from: data)
}

private let decoder = JSONDecoder()

public func createMRUsingGitCommand(
    sourceBranch: String,
    targetBranch: String,
    title: String,
    squash: Bool
) throws {
    var command = "git push --set-upstream origin \(sourceBranch) -o merge_request.create -o merge_request.target=\(targetBranch) -o merge_request.title=\"\(title)\" -o merge_request.remove_source_branch"
    if squash {
        command += " -o merge_request.squash"
    }
    try runInShell(command)
}
