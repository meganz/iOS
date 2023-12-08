import SharedReleaseScript

func commentInMR(gitlabMR: GitlabMR, message: String) async throws {
    let url = try makeURL(
        base: environment.gitlabBaseURL,
        path: "/api/v4/projects/\(environment.gitlabProjectId)/merge_requests/\(gitlabMR.iid)/notes",
        queryItems: [
            .init(name: "body", value: message)
        ]
    )

    try await sendRequest(url: url, method: .post, token: .bearer(environment.gitlabToken))
}
