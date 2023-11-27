import Foundation

public enum EnvironmentError: Error {
    case missingEnvironmentVariable(variable: EnvironmentVariable)
    case badJiraURL
    case badJiraProjectStrings
}

public enum EnvironmentVariable: String {
    case jiraBaseURL = "JIRA_BASE_URL"
    case jiraToken = "JIRA_TOKEN"
    case jiraProjects = "JIRA_PROJECTS"
    case slackToken = "SLACK_TOKEN"
    case releaseCandidateSlackChannelIds = "RC_MESSAGE_SLACK_IDS"
    case codeFreezeSlackChannelIds = "CODE_FREEZE_MESSAGE_SLACK_IDS"
}

public struct JiraProject: Decodable {
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
}

// '!' is intentional as we want the script to fail if the environment is malformed
public let environment = try! makeEnvironment()

private func makeEnvironment() throws -> Environment {
    let jiraBaseURLString = try environmentVariableString(.jiraBaseURL)

    guard let jiraBaseURL = URL(string: jiraBaseURLString) else {
        throw EnvironmentError.badJiraURL
    }

    let jiraProjectsString = try environmentVariableString(.jiraProjects)
    let jiraProjects = try parseJiraProjects(from: jiraProjectsString)

    let jiraToken = try environmentVariableString(.jiraToken)
    let slackToken = try environmentVariableString(.slackToken)

    let releaseCandidateSlackChannelIds = try environmentVariableString(.releaseCandidateSlackChannelIds).components(separatedBy: ",")
    let codeFreezeSlackChannelIds = try environmentVariableString(.codeFreezeSlackChannelIds).components(separatedBy: ",")

    return .init(
        jiraBaseURL: jiraBaseURL,
        jiraToken: jiraToken,
        jiraProjects: jiraProjects,
        slackToken: slackToken,
        releaseCandidateSlackChannelIds: releaseCandidateSlackChannelIds,
        codeFreezeSlackChannelIds: codeFreezeSlackChannelIds
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
