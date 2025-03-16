import Foundation

public func createReleaseVersion(version: String) async throws {
    let releasePath = "/rest/api/2/version"
    let url = try makeURL(base: environment.jiraBaseURL, path: releasePath)

    // Execute release creation concurrently for all projects
    await withThrowingTaskGroup(of: Void.self) { group in
        for project in environment.jiraProjects {
            group.addTask {
                try await createReleaseVersion(project: project, version: version, jiraURL: url)
            }
        }
    }
}

private func createReleaseVersion(project: JiraProject, version: String, jiraURL: URL) async throws {
    let body: [String: Any] = [
        "name": "iOS \(version)",
        "project": project.name,
        "projectId": project.id,
        "startDate": iso8601Formatter.string(from: .now)
    ]

    try await sendRequest(
        url: jiraURL,
        method: .post,
        token: .bearer(environment.jiraToken),
        headers: [.init(field: "Content-Type", value: "application/json")],
        body: body
    )
}

public func parseProjects(from input: String) -> [JiraProject] {
    var projects: [JiraProject] = []
    var invalidEntries: [String] = []

    for pair in input.split(separator: ",") {
        let components = pair.split(separator: ":")
        if components.count == 2, let id = Int64(components[1]) {
            projects.append(JiraProject(name: String(components[0]), id: id))
        } else {
            invalidEntries.append(String(pair))
        }
    }

    if !invalidEntries.isEmpty {
        print("⚠️ Warning: Ignored invalid Jira projects: \(invalidEntries.joined(separator: ", "))")
    }

    return projects
}
