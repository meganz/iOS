public struct ReleaseInput {
    public let version: String
    public let message: String
}

public func releaseInput() throws -> ReleaseInput {
    let version = if let version = readFromCache(key: .version) {
        version
    } else {
        try majorMinorOrMajorMinorPatchInput(
            "Enter the version number you're releasing (format: '[major].[minor]' or '[major].[minor].[patch]')"
        )
    }

    let message = if let message = readFromCache(key: .releaseNotes) {
        message
    } else {
        try releaseNotesInput(defaultReleaseNotes: defaultReleaseNotesInput())
    }

    return .init(version: version, message: message)
}

public func defaultReleaseNotesTemplate(
    sdkVersion: String,
    chatVersion: String
) -> String {
    """
    Bug fixes and performance improvements.
    - SDK release - release/v\(sdkVersion)
    - MEGAChat release - release/v\(chatVersion)
    """
}

private func defaultReleaseNotesInput() throws -> String {
    let sdkVersion = if let sdkVersion = readFromCache(key: .sdkVersion) {
        sdkVersion
    } else {
        try submoduleVersionInput(.sdk)
    }

    let chatVersion = if let chatVersion = readFromCache(key: .chatVersion) {
        chatVersion
    } else {
        try submoduleVersionInput(.chatSDK)
    }

    return defaultReleaseNotesTemplate(sdkVersion: sdkVersion, chatVersion: chatVersion)
}

private func submoduleVersionInput(_ submodule: Submodule) throws -> String {
    let message = "Enter the version number for \(submodule.description) (format: '[major].[minor].[patch]'):"
    return try majorMinorPatchInput(message)
}
