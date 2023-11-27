import SharedReleaseScript

struct UserInput {
    let version: String
    let message: String
}

func userInput() throws -> UserInput {
    let version = try majorMinorOrMajorMinorPatchInput("Enter the version number you're releasing (format: '[major].[minor]' or '[major].[minor].[patch]'):")
    let message = try releaseNotesInput(defaultReleaseNotes: defaultReleaseNotesInput())
    return .init(version: version, message: message)
}

private func defaultReleaseNotesInput() throws -> String {
    let sdkVersion = try submoduleVersionInput(.sdk)
    let chatVersion = try submoduleVersionInput(.chatSDK)

    let defaultReleaseNotes =
    """
    Bug fixes and performance improvements.
    - SDK release - release/v\(sdkVersion)
    - MEGAChat release - release/v\(chatVersion)
    """

    return defaultReleaseNotes
}

private func submoduleVersionInput(_ submodule: Submodule) throws -> String {
    let message = "Enter the version number for \(submodule.description) (format: '[major].[minor].[patch]'):"
    return try majorMinorPatchInput(message)
}
