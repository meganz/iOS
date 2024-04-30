import SharedReleaseScript

struct UserInput {
    let tag: String
    let hotfixVersion: String
}

func userInput() throws -> UserInput {
    let tag = if let tag = readFromCache(key: .version) {
        tag
    } else {
        try majorMinorOrMajorMinorPatchInput(
            "Enter the version number (format: '[major].[minor]' or '[major].[minor].[patch]') of the version you're creating a hotfix for:"
        )
    }

    let hotfixVersion = try majorMinorOrMajorMinorPatchInput("Enter the hotfix version number (format: '[major].[minor].[patch]'):")
    writeToCache(key: .version, value: hotfixVersion)

    return .init(tag: tag, hotfixVersion: hotfixVersion)
}
