import SharedReleaseScript

struct UserInput {
    let tag: String
    let hotfixVersion: String
}

func userInput() throws -> UserInput {
    let tag = if let tag = try? latestTag() {
        tag
    } else {
        try askUserForTagVersion()
    }

    let hotfixVersion = if let version = try? upcomingHotfixPatchVersion() {
        version
    } else {
        try askUserForHotfixVersion()
    }

    return try askUserForConfirmation(tag: tag, hotfixVersion: hotfixVersion)
}

private func askUserForConfirmation(tag: String, hotfixVersion: String) throws -> UserInput {
    print("""
    ------------------------------------------------------------
    From tag        : \(tag)
    Create Hotfix   : \(hotfixVersion)
    Would you like to continue with the details above?
    ------------------------------------------------------------
    """)
    print("(yes/no) - Your input: ", terminator: "")

    guard let input = readLine() else {
        throw InputError.missingInput
    }

    let matchesYes = try matchesYes(input)
    let matchesNo = try matchesNo(input)

    switch input {
    case input where matchesYes:
        return .init(tag: tag, hotfixVersion: hotfixVersion)
    case input where matchesNo:
        return .init(tag: try askUserForTagVersion(), hotfixVersion: try askUserForHotfixVersion())
    default:
        throw InputError.wrongInput
    }
}

private func askUserForTagVersion() throws -> String {
    try majorMinorOrMajorMinorPatchInput(
        "Enter the tag in the format '[major].[minor]' or '[major].[minor].[patch]' from which you are creating a hotfix:"
    )
}

private func askUserForHotfixVersion() throws -> String {
    try majorMinorOrMajorMinorPatchInput("Enter the hotfix version number (format: '[major].[minor].[patch]'):")
}
