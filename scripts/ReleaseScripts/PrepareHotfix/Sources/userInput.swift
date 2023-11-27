import SharedReleaseScript

struct UserInput {
    let tag: String
    let hotfixVersion: String
}

func userInput() throws -> UserInput {
    let tagMessage = "Enter the version number (format: '[major].[minor]' or '[major].[minor].[patch]') of the version you're creating a hotfix for:"
    let tag = try majorMinorOrMajorMinorPatchInput(tagMessage)

    let hotfixVersion = try majorMinorOrMajorMinorPatchInput("Enter the hotfix version number (format: '[major].[minor].[patch]'):")

    return .init(tag: tag, hotfixVersion: hotfixVersion)
}
