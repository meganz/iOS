import Foundation
import SharedReleaseScript

struct Fetcher {
    let api: API
    private let numberOfTries = 3

    func fetch() async throws -> Data {
        var data = try await downloadData(from: try await downloadLink())

        // Sometimes the initial response contains a placeholder (e.g., a download link) instead of the actual data.
        // In such cases, we attempt to follow the link and refetch the data, retrying a few times if needed.
        for tryNumber in 1..<(numberOfTries + 1) {
            do {
                // Try checking if the link is present in the response instead of the actual data
                let link = try parseDownloadLink(using: data)

                // Sleep for 2 seconds before trying again
                try await Task.sleep(for: .seconds(2))

                print("\(tryNumber) - The data wasn't ready the last time - Try refetching it")
                data = try await downloadData(from: link)
            } catch {
                break
            }
        }

        return data
    }

    private func downloadLink() async throws -> URL {
        let downloadLinkResponseData = try await sendRequest(
            url: api.url,
            method: .post,
            headers: api.headers,
            body: try api.body.toJSON()
        )

        return try parseDownloadLink(using: downloadLinkResponseData)
    }

    private func parseDownloadLink(using response: Data) throws -> URL {
        let downloadLinkResponse = try JSONDecoder().decode(DownloadLinkResponse.self, from: response)
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
