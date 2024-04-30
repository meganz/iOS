import SharedReleaseScript

struct UserInput {
    let version: String
    let sdkHash: String
    let chatHash: String
}

func userInput() throws -> UserInput {
    let version = try majorMinorInput("Enter the version number you're releasing (format: '[major].[minor]'):")
    writeToCache(key: .version, value: version)

    let sdkHash = try commitHashFromUser(submodule: .sdk)
    writeToCache(key: .sdkHash, value: sdkHash)

    let chatHash = try commitHashFromUser(submodule: .chatSDK)
    writeToCache(key: .chatHash, value: chatHash)

    return .init(version: version, sdkHash: sdkHash, chatHash: chatHash)
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
