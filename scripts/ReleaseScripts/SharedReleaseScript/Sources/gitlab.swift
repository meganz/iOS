import Foundation

public struct GitlabMR: Decodable {
    public let title: String
    // 'iid' stands for "Internal Id" in GitLab's API: https://docs.gitlab.com/ee/api/rest/#id-vs-iid
    public let iid: Int
}

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
