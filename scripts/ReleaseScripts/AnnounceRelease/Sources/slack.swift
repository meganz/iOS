import Foundation
import SharedReleaseScript

enum SlackError: Error {
    case badSlackURL
}

func sendReleaseCandidateMessage(input: UserInput) async throws {
    // Execute message sending concurrently for all channels
    await withThrowingTaskGroup(of: Void.self) { group in
        for channel in environment.releaseCandidateSlackChannelIds {
            group.addTask {
                try await sendReleaseCandidateMessage(input: input, channelId: channel)
            }
        }
    }
}

func sendCodeFreezeReminderMessage(version: String, nextVersion: String) async throws {
    // Execute message sending concurrently for all channels
    await withThrowingTaskGroup(of: Void.self) { group in
        for channel in environment.codeFreezeSlackChannelIds {
            group.addTask {
                try await sendCodeFreezeReminderMessage(version: version, nextVersion: nextVersion, channelId: channel)
            }
        }
    }
}

private func sendReleaseCandidateMessage(input: UserInput, channelId: String) async throws {
    let body = [
        "channel": channelId,
        "text":
        """
        Hi <!here>, the iOS team has uploaded a new <\(input.testFlightLink)|Release Candidate build \(input.version)> to TestFlight.
        - SDK release `release/\(input.sdkVersion)`
        - MEGAChat release `release/\(input.chatVersion)`

        <\(input.jiraReleasePackageLink)|\(input.version) JIRA Release Package>

        *Release notes*:
        - \(input.releaseNotes)
        """
    ]

    try await sendMessageToChannel(body: body)
}

private func sendCodeFreezeReminderMessage(version: String, nextVersion: String, channelId: String) async throws {
    let body = [
        "channel": channelId,
        "text":
        """
        Hi iOS team, we have started the Code Freeze for version iOS \(version). Any tickets merged to develop should now use the next Fix Version iOS \(nextVersion). Thanks!
        """
    ]

    try await sendMessageToChannel(body: body)
}

private func sendMessageToChannel(body: [String: Any]) async throws {
    guard let url = URL(string: "https://slack.com/api/chat.postMessage") else {
        throw SlackError.badSlackURL
    }

    try await sendRequest(
        url: url,
        method: .post,
        token: .bearer(environment.slackToken),
        headers: [.init(field: "Content-Type", value: "application/json")],
        body: body
    )
}
