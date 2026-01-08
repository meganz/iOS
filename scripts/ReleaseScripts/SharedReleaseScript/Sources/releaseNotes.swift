import Foundation
import RegexBuilder

enum ReleaseNotesFetchError: Error {
    case dataToStringConversionError
    case couldNotFindReleaseNotesInChangeLogs
}

public func fetchReleaseNotes(for version: String, token: String) async throws -> String {
    let changeLogs = try await fetchChangeLogs(token: token)
    var log: String? = specificChangeLog(for: version, in: changeLogs)
    if log == nil {
        log = basicChangeLog(in: changeLogs)
    }
    guard let log else { throw ReleaseNotesFetchError.couldNotFindReleaseNotesInChangeLogs }
    return log
}

private func fetchChangeLogs(token: String) async throws -> String {
    var headers = headers(for: token)
    headers.append(.init(field: "Content-Type", value: "application/json"))

    let data = try await sendRequest(
        url: URL(string: "https://translate.developers.mega.co.nz/api/translations/ios/changelogs/en/file/")!,
        method: .get,
        headers: headers,
    )

    guard let changeLogs = String(data: data, encoding: .utf16) else {
        throw ReleaseNotesFetchError.dataToStringConversionError
    }

    return changeLogs
}

private func specificChangeLog(for version: String, in changeLogs: String) -> String? {
    let regex = Regex {
        "\""
        OneOrMore(.any, .reluctant)
        formattedVersion(version)
        "\""
        ZeroOrMore(.whitespace)
        "="
        ZeroOrMore(.whitespace)
        "\""
        Capture {
            OneOrMore(.any, .reluctant)
        }
        "\";"
    }

    return changeLogs.firstMatch(of: regex).map {
        String($0.output.1).replacingOccurrences(of: "[Br]", with: "\n")
    }
}

private func basicChangeLog(in changeLogs: String) -> String? {
    let regex = Regex {
        "\"Changelog basic\""
        ZeroOrMore(.whitespace)
        "="
        ZeroOrMore(.whitespace)
        "\""
        Capture {
            OneOrMore(.any, .reluctant)
        }
        "\";"
    }

    return changeLogs.firstMatch(of: regex).map {
        String($0.output.1).replacingOccurrences(of: "[Br]", with: "\n")
    }
}

private func formattedVersion(_ version: String) -> String {
    let components = version.split(separator: ".")
    guard components.count >= 2 else { return version + ".0" }
    return "\(components[0]).\(components[1])"
}

private func headers(for token: String) -> [HTTPHeader] {
    if token.contains("Token ") {
        return [HTTPHeader(field: "Authorization", value: token)]
    } else {
        return [HTTPHeader(field: "Authorization", value: "Token \(token)")]
    }
}
