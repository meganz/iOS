import SharedReleaseScript

struct UserInput {
    let tag: String
    let hotfixVersion: String
}

func userInput() throws -> UserInput {
    let tag = try tagInput()
    let hotfixVersion = try hotfixVersionInput()

    return .init(tag: tag, hotfixVersion: hotfixVersion)
}

private func tagInput() throws -> String {
    while true {
        print(
            "Enter the version number (format: '[major].[minor]' or '[major].[minor].[patch]') of the version you're creating a hotfix for:",
            terminator: " "
        )
        if let input = readLine() {
            let matchesMajorMinor = try matchesMajorMinorRelease(input)
            let matchesMajorMinorPatch = try matchesMajorMinorPatchRelease(input)
            if matchesMajorMinor || matchesMajorMinorPatch {
                return input
            } else {
                print("Invalid format. Please make sure to follow the '[major].[minor]' or '[major].[minor].[patch]' format.")
            }
        }
    }
}

private func hotfixVersionInput() throws -> String {
    while true {
        print("Enter the hotfix version number (format: '[major].[minor].[patch]'):", terminator: " ")
        if let input = readLine() {
            let matches = try matchesMajorMinorPatchRelease(input)
            if matches {
                return input
            } else {
                print("Invalid format. Please make sure to follow the '[major].[minor].[patch]' format.")
            }
        }
    }
}
