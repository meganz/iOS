import Foundation
import RegexBuilder

enum ReleaseNotesFetchError: Error {
    case stringToDataConversionError
    case dataToDictConversionError
    case couldNotReadTheLinkFromTheFirstAPI
    case couldNotConvertDataToString
    case couldNotFindReleaseNotesInChangeLogs
    case couldNotCreateURLFromString
}

public func fetchReleaseNotes(for version: String, resourceID: String, token: String) async throws -> String {
    let changeLogsURL = try await fetchChangeLogsURL(resourceID: resourceID, token: token)
    let changeLogs = try await fetchChangeLogs(for: changeLogsURL, token: token)
    var log: String? = specificChangeLog(for: version, in: changeLogs)
    if log == nil {
        log = basicChangeLog(in: changeLogs)
    }
    guard let log else { throw ReleaseNotesFetchError.couldNotFindReleaseNotesInChangeLogs }
    return log
}

private func fetchChangeLogs(for url: URL, token: String) async throws -> String {
    let changeLogsData = try await sendRequest(
        url: url,
        method: .get,
        headers: headers(for: token)
    )
    guard let changeLogs = String(data: changeLogsData, encoding: .utf16) else {
        throw ReleaseNotesFetchError.couldNotConvertDataToString
    }
    return changeLogs
}

private func fetchChangeLogsURL(resourceID: String, token: String) async throws -> URL {
    let body = try makeBody(with: resourceID)
    var headers = headers(for: token)
    headers.append(.init(field: "Content-Type", value: "application/vnd.api+json"))
    let result = try await sendRequest(
        url: URL(string: "https://rest.api.transifex.com/resource_strings_async_downloads")!,
        method: .post,
        headers: headers,
        body: body
    )

    guard let jsonObject = try JSONSerialization.jsonObject(with: result, options: []) as? [String: Any],
          let data = jsonObject["data"] as? [String: Any],
          let links = data["links"] as? [String: Any],
          let selfLink = links["self"] as? String else {
        throw ReleaseNotesFetchError.couldNotReadTheLinkFromTheFirstAPI
    }

    guard let link = URL(string: selfLink) else { throw ReleaseNotesFetchError.couldNotCreateURLFromString }
    return link
}

private func makeBody(with resourceID: String) throws -> [String: Any] {
    let jsonStringTemplate = """
    {
      "data": {
        "attributes": {
          "content_encoding": "text",
          "file_type": "default"
        },
        "relationships": {
          "resource": {
            "data": {
              "id": "{{RESOURCE_ID}}",
              "type": "resources"
            }
          }
        },
        "type": "resource_strings_async_downloads"
      }
    }
    """

    let updatedJsonString = jsonStringTemplate.replacingOccurrences(of: "{{RESOURCE_ID}}", with: resourceID)

    guard let jsonData = updatedJsonString.data(using: .utf8) else {
        throw ReleaseNotesFetchError.stringToDataConversionError
    }

    guard let jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] else {
        throw ReleaseNotesFetchError.dataToDictConversionError
    }

    return jsonDict
}

private func specificChangeLog(for version: String, in changeLogs: String) -> String? {
    let regex = Regex {
        "\""
        Capture {
            OneOrMore(.any, .reluctant)
        }
        " "
        formattedVersion(version)
        "\"=\""
        Capture {
            OneOrMore(.any, .reluctant)
        }
        "\";"
    }

    return changeLogs.firstMatch(of: regex)?.output.2.replacingOccurrences(of: "[Br]", with: "\n")
}

private func basicChangeLog(in changeLogs: String) -> String? {
    let regex = Regex {
        "\"Changelog basic\"=\""
        Capture {
            OneOrMore(.any, .reluctant)
        }
        "\";"
    }

    return changeLogs.firstMatch(of: regex)?.output.1.replacingOccurrences(of: "[Br]", with: "\n")
}

private func formattedVersion(_ version: String) -> String {
    let components = version.split(separator: ".")
    guard components.count >= 2 else { return version + ".0" }
    return "\(components[0]).\(components[1])"
}

private func headers(for token: String) -> [HTTPHeader] {
    if token.contains("Bearer ") {
        return [HTTPHeader(field: "Authorization", value: token)]
    } else {
        return [HTTPHeader(field: "Authorization", value: "Bearer \(token)")]
    }
}
