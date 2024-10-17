import Foundation
import Yams
import SharedReleaseScript

struct Fetcher {
    let url: URL
    let httpBody: HttpBody
    let languageInfo: LanguageInfo

    private var headers: [HTTPHeader] {
        [
            HTTPHeader(field: "accept", value: "*/*"),
            HTTPHeader(field: "content-type", value: "application/vnd.api+json")
        ]
    }

    func fetch(with authorization: String) async throws -> String {
        let downloadLink = try await downloadLink(with: authorization)
        return try await downloadDescription(with: downloadLink, authorization: authorization)
    }

    private func downloadLink(with authorization: String) async throws -> URL {
        let body = try httpBody.toJSON()
        let downloadLinkResponseData = try await sendRequest(
            url: url,
            method: .post,
            token: .other(HTTPHeader(field: "Authorization", value: authorization)),
            headers: headers,
            body: body
        )

        let downloadLinkResponse = try JSONDecoder().decode(DownloadLinkResponse.self, from: downloadLinkResponseData)
        guard let link = URL(string: downloadLinkResponse.data.links.link) else {
            throw "Link isn't available in the downloaded Link response."
        }

        return link
    }

    private func downloadDescription(with downloadLink: URL, authorization: String) async throws -> String {
        let descriptionData = try await sendRequest(
            url: downloadLink,
            method: .get,
            token: .other(HTTPHeader(field: "Authorization", value: authorization)),
            headers: headers,
            body: nil
        )

        let yAMLDecoder = YAMLDecoder()
        let appDescription = try yAMLDecoder.decode(AppDescription.self, from: descriptionData)
        return try appDescription.formattedString
    }
}
