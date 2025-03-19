import Foundation
import SharedReleaseScript

struct SlackMessageSender {

    static func sendReleaseCandidateMessage(
        releaseCandidateSlackChannelIds: [String],
        version: String,
        buildNumber: String,
        sdkVersion: SubmoduleReferenceType,
        chatSDKVersion: SubmoduleReferenceType,
        jiraBaseURLString: String,
        releaseNotes: String,
        token: String,
        testflightBaseUrl: String
    ) async throws {
        var failedChannels: [String] = []

        // Execute message sending concurrently for all channels
        await withTaskGroup(of: (String, Bool).self) { group in
            for channel in releaseCandidateSlackChannelIds {
                group.addTask {
                    do {
                        try await sendReleaseCandidateMessage(
                            channelId: channel,
                            version: version,
                            buildNumber: buildNumber,
                            sdkVersion: sdkVersion,
                            chatSDKVersion: chatSDKVersion,
                            jiraBaseURLString: jiraBaseURLString,
                            releaseNotes: releaseNotes,
                            token: token,
                            testflightBaseUrl: testflightBaseUrl
                        )
                        return (channel, true)
                    } catch {
                        return (channel, false)
                    }
                }

                for await (channel, success) in group {
                    if !success {
                        failedChannels.append(channel)
                    }
                }
            }
        }

        if !failedChannels.isEmpty {
            let message = "Failed to send RC message to Slack channels: \(failedChannels.joined(separator: ", "))"
            throw AppError.failedToSendMessage(message)
        }
    }

    static func sendCodeFreezeReminderMessage(
        codeFreezeSlackChannelIds: [String],
        version: String,
        nextVersion: String,
        token: String
    ) async throws {
        // Execute message sending concurrently for all channels
        await withThrowingTaskGroup(of: Void.self) { group in
            for channel in codeFreezeSlackChannelIds {
                group.addTask {
                    try await sendCodeFreezeReminderMessage(
                        version: version,
                        nextVersion: nextVersion,
                        channelId: channel,
                        token: token
                    )
                }
            }
        }
    }

    private static func sendCodeFreezeReminderMessage(
        version: String,
        nextVersion: String,
        channelId: String,
        token: String
    ) async throws {
        let body = [
            "channel": channelId,
            "text":
        """
        Hi iOS team, we have started the Code Freeze for version iOS \(version). Any tickets merged to develop should now use the next Fix Version iOS \(nextVersion). Thanks!
        """
        ]

        try await sendMessageToChannel(body: body, token: token)
    }

    private static func sendReleaseCandidateMessage(
        channelId: String,
        version: String,
        buildNumber: String,
        sdkVersion: SubmoduleReferenceType,
        chatSDKVersion: SubmoduleReferenceType,
        jiraBaseURLString: String,
        releaseNotes: String,
        token: String,
        testflightBaseUrl: String
    ) async throws {
        let jiraReleasePackageLink = jiraBaseURLString + "/issues/?jql=fixVersion%20%3D%20%22iOS%20\(version)%22"
        let testFlightLink = "\(testflightBaseUrl)\(buildNumber)"

        let body = [
            "channel": channelId,
            "text":
        """
        *🚀 New iOS Release Candidate Available!*
        *Version:* <\(testFlightLink)|\(version)(\(buildNumber))>
        • \(sdkVersion.description(type: "SDK"))
        • \(chatSDKVersion.description(type: "Chat SDK"))
        
        🔗 <\(jiraReleasePackageLink)|View Jira Release Package>
        
        *📌 Release Notes:*
        ```
        \(releaseNotes)
        ```
        """
        ]

        try await sendMessageToChannel(body: body, token: token)
    }


    private static func sendMessageToChannel(body: [String: Any], token: String) async throws {
        guard let url = URL(string: "https://slack.com/api/chat.postMessage") else {
            throw AppError.invalidURL("bad Slack URl")
        }

        try await sendRequest(
            url: url,
            method: .post,
            token: .bearer(token),
            headers: [.init(field: "Content-Type", value: "application/json")],
            body: body
        )
    }
}
