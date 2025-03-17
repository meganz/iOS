import Foundation
import SharedReleaseScript

struct Fetcher {
    let api: API

    func fetch() async throws -> Data {
        try await downloadData(from: try await downloadLink())
    }

    private func downloadLink() async throws -> URL {
        let downloadLinkResponseData = try await sendRequest(
            url: api.url,
            method: .post,
            headers: api.headers,
            body: try api.body.toJSON()
        )

        let downloadLinkResponse = try JSONDecoder().decode(DownloadLinkResponse.self, from: downloadLinkResponseData)
        guard let link = URL(string: downloadLinkResponse.data.links.link) else {
            throw "Link isn't available in the downloaded Link response."
        }

        return link
    }

    private func downloadData(from url: URL) async throws -> Data {
        let data = try await sendRequest(
            url: url,
            method: .get,
            headers: api.headers,
            body: nil
        )

        print(
        """
        Sending request:
            - URL: \(url.absoluteString)
            - headers: \(String(describing: api.headers))
        Data:
            - utf8 data: \(String(data: data, encoding: .utf8) ?? "Could not convert to utf8")
            - utf16 data: \(String(data: data, encoding: .utf16) ?? "Could not convert to utf16")
        """
        )

        return data
    }
}
