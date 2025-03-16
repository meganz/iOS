import Foundation

public enum EnvironmentError: Error {
    case missingEnvironmentVariable(variable: EnvironmentVariable)
    case badJiraProjectStrings
    case badURL(reason: String)
}

public enum EnvironmentVariable: String, Equatable {
    case jiraBaseURL = "JIRA_BASE_URL"
    case jiraToken = "JIRA_TOKEN"
    case jiraProjects = "JIRA_PROJECTS"
    case slackToken = "SLACK_TOKEN"
    case releaseCandidateSlackChannelIds = "RC_MESSAGE_SLACK_IDS"
    case codeFreezeSlackChannelIds = "CODE_FREEZE_MESSAGE_SLACK_IDS"
    case gitlabBaseURL = "GITLAB_BASE_URL"
    case gitlabProjectId = "GITLAB_PROJECT_ID"
    case gitlabToken = "GITLAB_TOKEN"
}

public struct JiraProject: Decodable, Sendable {
    public let name: String
    public let id: Int64
}

public struct Environment {
    public let jiraBaseURL: URL
    public let jiraToken: String
    public let jiraProjects: [JiraProject]
    public let slackToken: String
    public let releaseCandidateSlackChannelIds: [String]
    public let codeFreezeSlackChannelIds: [String]
    public let gitlabBaseURL : URL
    public let gitlabProjectId: String
    public let gitlabToken: String
}

// '!' is intentional as we want the script to fail if the environment is malformed
public let environment = try! makeEnvironment()

// TODO: Create three separate and independent environments: Jira, Slack and Gitlab
private func makeEnvironment() throws -> Environment {
    let jiraBaseURL = try parseURL(.jiraBaseURL)
    let jiraProjectsString = try environmentVariableString(.jiraProjects)
    let jiraProjects = try parseJiraProjects(from: jiraProjectsString)
    let jiraToken = try environmentVariableString(.jiraToken)

    let slackToken = try environmentVariableString(.slackToken)
    let releaseCandidateSlackChannelIds = try environmentVariableString(.releaseCandidateSlackChannelIds)
        .components(separatedBy: ",")
    let codeFreezeSlackChannelIds = try environmentVariableString(.codeFreezeSlackChannelIds)
        .components(separatedBy: ",")

    let gitlabBaseURL = try parseURL(.gitlabBaseURL)
    let gitlabProjectId = try environmentVariableString(.gitlabProjectId)
    let gitlabToken = try environmentVariableString(.gitlabToken)

    return .init(
        jiraBaseURL: jiraBaseURL,
        jiraToken: jiraToken,
        jiraProjects: jiraProjects,
        slackToken: slackToken,
        releaseCandidateSlackChannelIds: releaseCandidateSlackChannelIds,
        codeFreezeSlackChannelIds: codeFreezeSlackChannelIds,
        gitlabBaseURL: gitlabBaseURL,
        gitlabProjectId: gitlabProjectId,
        gitlabToken: gitlabToken
    )
}

private func environmentVariableString(_ variable: EnvironmentVariable) throws -> String {
    guard let variableString = ProcessInfo.processInfo.environment[variable.rawValue] else {
        throw EnvironmentError.missingEnvironmentVariable(variable: variable)
    }

    return variableString
}

private func parseJiraProjects(from string: String) throws -> [JiraProject] {
    let projectStrings = string.split(separator: ",")

    return try projectStrings.map { projectString in
        let components = projectString.split(separator: ":")

        guard components.count == 2, let id = Int64(components[1]) else {
            throw EnvironmentError.badJiraProjectStrings
        }

        let name = String(components[0])

        return .init(name: name, id: id)
    }
}

private func parseURL(_ variable: EnvironmentVariable) throws -> URL {
    guard variable == .jiraBaseURL || variable == .gitlabBaseURL else {
        throw EnvironmentError.badURL(reason: "Environment variable \(String(describing: variable)) is not a URL")
    }

    let baseURLString = try environmentVariableString(variable)

    guard let baseURL = URL(string: baseURLString) else {
        throw EnvironmentError.badURL(reason: "Bad URL formation for \(String(describing: baseURLString))")
    }

    return baseURL
}
