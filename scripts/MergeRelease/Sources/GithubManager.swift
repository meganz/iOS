import Foundation
import SharedReleaseScript

struct GithubManager {
    static func pushMasterToPublicAndCreateRelease(
        for version: String,
        githubAccessToken: String,
        message: String
    ) async throws {
        try runInShell("git remote add public https://megaiospush:\(githubAccessToken)@github.com/meganz/iOS.git")
        try runInShell("git fetch public")
        try runInShell("git fetch origin")
        try runInShell("git checkout origin/lf/Fix-the-merge-release-script-issue")
        try runInShell("git pull origin lf/Fix-the-merge-release-script-issue")
        try runInShell("git config http.postBuffer 100000000")
        try runInShell("git push public origin/lf/Fix-the-merge-release-script-issue")
//        try await createReleaseOnGithub(
//            for: version,
//            githubBearerToken: githubAccessToken,
//            message: message
//        )
    }

    static func createReleaseOnGithub(
        for version: String,
        githubBearerToken: String,
        message: String
    ) async throws {
        let body: [String: Any] = [
            "tag_name": version,
            "target_commitish":"master",
            "name": version,
            "body": message,
        ]

        try await sendRequest(
            url: URL(string: "https://api.github.com/repos/meganz/iOS/releases")!,
            method: .post,
            token: .bearer(githubBearerToken),
            headers: [
                .init(field: "Accept", value: "application/vnd.github+json"),
            ],
            body: body
        )
    }
}
