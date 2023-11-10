import Foundation

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
    let versionPattern = "^(\\d+)\\.(\\d+)$" // Regex pattern for 'major.minor'
    let regex = try NSRegularExpression(pattern: versionPattern, options: [])

    while true {
        print("Enter the version number (format: '[major].[minor]'):", terminator: " ")
        if let versionInput = readLine() {
            if regex.firstMatch(in: versionInput, options: [], range: NSRange(location: 0, length: versionInput.utf16.count)) != nil {
                return versionInput
            } else {
                print("Invalid format. Please make sure to follow the '[major].[minor]' format.")
            }
        }
    }
}

private func commitHashFromUser(submodule: Submodule) throws -> String {
    print("Enter the commit hash for the \(submodule.description) release:", terminator: " ")

    guard let hash = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
        throw InputError.missingReleaseCommitHash(submodule: submodule)
    }

    // Regex pattern for git-style commit hashes with 7 and a maximum of 40 hexadecimal characters
    let commitHashPattern = "^[0-9a-f]{7,40}$"
    let regex = try NSRegularExpression(pattern: commitHashPattern, options: [.caseInsensitive])
    let matches = regex.firstMatch(in: hash, options: [], range: NSRange(location: 0, length: hash.utf16.count)) != nil

    guard matches else {
        throw InputError.invalidCommitHash(submodule: submodule)
    }

    return hash
}
