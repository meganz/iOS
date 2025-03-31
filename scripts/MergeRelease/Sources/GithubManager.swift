import Foundation
import SharedReleaseScript

struct GithubManager {
    static func pushMasterToPublicAndCreateRelease(
        for version: String,
        githubAccessToken: String,
        message: String
    ) async throws {
        try pushGitlabBranch(withName: "master", toGithubWithToken: githubAccessToken)

        try await createReleaseOnGithub(
            for: version,
            githubBearerToken: githubAccessToken,
            message: message
        )
    }

    private static func pushGitlabBranch(
        withName branchName: String,
        toGithubWithToken githubAccessToken: String
    ) throws {
        // checkout specified branch and pull the latest changes
        do {
            try runInShell("git checkout \(branchName)")
            try runInShell("git pull origin \(branchName)")
        } catch {
            print("Error checking out and pull from GitLab: \(error)")
            throw error
        }

        // Add the GitHub remote
        do {
            try runInShell("git remote add public https://megaiospush:\(githubAccessToken)@github.com/meganz/iOS.git")
            try runInShell("git fetch public")
        } catch {
            print("Error adding or fetching from the GitHub remote: \(error)")
            throw error
        }

        // Push the GitLab branch to GitHub
        do {
            try runInShell("git config http.postBuffer 100000000")
            try runInShell("git push public \(branchName)")
        } catch {
            print("Error pushing to GitHub: \(error)")
            throw error
        }
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
