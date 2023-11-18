import SharedReleaseScript

struct UserInput {
    let version: String
    let sdkHash: String
    let chatHash: String
}

enum InputError: Error {
    case missingReleaseCommitHash(submodule: Submodule)
    case invalidCommitHash(submodule: Submodule)
}

func userInput() throws -> UserInput {
    let version = try versionInput()
    let sdkHash = try commitHashFromUser(submodule: .sdk)
    let chatHash = try commitHashFromUser(submodule: .chatSDK)

    return .init(version: version, sdkHash: sdkHash, chatHash: chatHash)
}

private func versionInput() throws -> String {
    while true {
        print("Enter the version number (format: '[major].[minor]'):", terminator: " ")
        if let input = readLine() {
            let matches = try matchesMajorMinorRelease(input)
            if matches {
                return input
            } else {
                print("Invalid format. Please make sure to follow the '[major].[minor]' format.")
            }
        }
    }
}

private func commitHashFromUser(submodule: Submodule) throws -> String {
    print("Enter the commit hash for the \(submodule.description) release:", terminator: " ")

    guard let input = readLine() else {
        throw InputError.missingReleaseCommitHash(submodule: submodule)
    }

    let matches = try matchesGitCommitHash(input)

    guard matches else {
        throw InputError.invalidCommitHash(submodule: submodule)
    }

    return input
}
