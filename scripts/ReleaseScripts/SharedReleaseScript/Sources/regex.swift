import Foundation

public func matchesMajorMinorRelease(_ input: String) throws -> Bool {
    // Regex pattern for 'major.minor'
    let majorMinorPattern = "^(\\d+)\\.(\\d+)$"
    return try matches(pattern: majorMinorPattern, input: input)
}

public func matchesMajorMinorPatchRelease(_ input: String) throws -> Bool {
    // Regex pattern for 'major.minor.patch'
    let majorMinorPatchPattern = "^(\\d+)\\.(\\d+)\\.(\\d+)$"
    return try matches(pattern: majorMinorPatchPattern, input: input)
}

public func matchesGitCommitHash(_ input: String) throws -> Bool {
    // Regex pattern for git-style commit hashes with 7 and a maximum of 40 hexadecimal characters, case-insensitive
    let commitHashPattern = "^[0-9a-f]{7,40}$"
    return try matches(pattern: commitHashPattern, input: input, options: [.caseInsensitive])
}

public func matchesYes(_ input: String) throws -> Bool {
    // Regex pattern for 'yes', allowing leading/trailing spaces, case-insensitive
    let yesPattern = "^\\s*yes\\s*$"
    return try matches(pattern: yesPattern, input: input, options: [.caseInsensitive])
}

public func matchesNo(_ input: String) throws -> Bool {
    // Regex pattern for 'no', allowing leading/trailing spaces, case-insensitive
    let noPattern = "^\\s*no\\s*$"
    return try matches(pattern: noPattern, input: input, options: [.caseInsensitive])
}

private func matches(pattern: String, input: String, options: NSRegularExpression.Options = []) throws -> Bool {
    let regex = try NSRegularExpression(pattern: pattern, options: options)
    return regex.firstMatch(in: input, options: [], range: .init(location: .zero, length: input.utf16.count)) != nil
}
