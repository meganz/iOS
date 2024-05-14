import Foundation

public enum InputError: Error {
    case missingInput
    case wrongInput
    case missingReleaseCommitHash(submodule: Submodule)
    case invalidCommitHash(submodule: Submodule)
}

public func majorMinorInput(_ message: String) throws -> String {
    while true {
        print(message, terminator: " ")
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

public func majorMinorPatchInput(_ message: String) throws -> String {
    while true {
        print(message, terminator: " ")
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

public func majorMinorOrMajorMinorPatchInput(_ message: String) throws -> String {
    while true {
        print(message, terminator: " ")
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

public func urlInput(_ message: String) -> String {
    while true {
        print(message, terminator: " ")
        if let input = readLine() {
            if URL(string: input) != nil {
                return input
            } else {
                print("Invalid URL. Please enter a valid URL format.")
            }
        }
    }
}

private let defaultNotesTemplate = "Bug fixes and performance improvements."

public func releaseNotesInput(defaultReleaseNotes: @autoclosure () throws -> String) throws -> String {
    print("Do you want the default \"\(defaultNotesTemplate)\" message? (yes/no)")

    guard let input = readLine() else {
        throw InputError.missingInput
    }

    let matchesYes = try matchesYes(input)
    let matchesNo = try matchesNo(input)

    switch input {
    case input where matchesYes:
        return try defaultReleaseNotes()
    case input where matchesNo:
        return customReleaseNotes()
    default:
        throw InputError.wrongInput
    }
}

public extension String {
    var isDefaultReleaseNotes: Bool {
        self == defaultNotesTemplate
    }
}

private func customReleaseNotes() -> String {
    print("Enter your custom message (press Enter twice to finish):", terminator: " ")

    var message = ""
    while let line = readLine(), !line.isEmpty {
        message += line + "\n"
    }

    return message
}
