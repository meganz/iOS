import SharedReleaseScript

struct UserInput {
    let version: String
    let message: String
}

enum InputError: Error {
    case missingInput
    case wrongInput
}

func userInput() throws -> UserInput {
    let version = try versionInput()
    let message = try messageInput()
    return .init(version: version, message: message)
}

private func versionInput() throws -> String {
    while true {
        print("Enter the version number (format: '[major].[minor]' or '[major].[minor].[patch]'):", terminator: " ")
        if let input = readLine() {
            let matchesNormalRelease = try matchesMajorMinorRelease(input)
            let matchesHotfixRelease = try matchesMajorMinorPatchRelease(input)
            if matchesNormalRelease || matchesHotfixRelease {
                return input
            } else {
                print("Invalid format. Please make sure to follow the '[major].[minor]' or '[major].[minor].[patch]' format.")
            }
        }
    }
}

private func messageInput() throws -> String {
    print("Do you want the default \"Bug fixes and performance improvements.\" message? (yes/no)")

    guard let input = readLine() else {
        throw InputError.missingInput
    }

    let matchesYes = try matchesYes(input)
    let matchesNo = try matchesNo(input)

    switch input {
    case input where matchesYes:
        return try defaultMessageInput()
    case input where matchesNo:
        return customMessageInput()
    default:
        throw InputError.wrongInput
    }
}

private func defaultMessageInput() throws -> String {
    let sdkVersion = try submoduleVersionInput(.sdk)
    let chatVersion = try submoduleVersionInput(.chatSDK)

    let defaultMessage =
    """
    Bug fixes and performance improvements.
    - SDK release - release/v\(sdkVersion)
    - MEGAChat release - release/v\(chatVersion)
    """

    return defaultMessage
}

private func submoduleVersionInput(_ submodule: Submodule) throws -> String {
    while true {
        print("Enter the version number for \(submodule.description) (format: '[major].[minor].[patch]'):", terminator: " ")
        if let input = readLine() {
            let matchesSubmoduleRelease = try matchesMajorMinorPatchRelease(input)
            if matchesSubmoduleRelease {
                return input
            } else {
                print("Invalid format. Please make sure to follow the '[major].[minor].[patch]' format.")
            }
        }
    }
}

private func customMessageInput() -> String {
    print("Enter your custom message (press Enter twice to finish):")

    var message = ""
    while let line = readLine(), !line.isEmpty {
        message += line + "\n"
    }

    return message
}
