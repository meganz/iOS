import Foundation
import SharedReleaseScript

struct Fetcher {
    let api: API
    private let numberOfTries = 3

    func fetch() async throws -> Data {
        // Sometimes the initial response contains a placeholder (e.g., a download link) instead of the actual data.
        // In such cases, we attempt to follow the link and refetch the data, retrying a few times if needed.
        for tryNumber in 1..<(numberOfTries + 1) {
            do {
                if tryNumber > 1 {
                    // Sleep for 2 seconds before trying again
                    try await Task.sleep(for: .seconds(2))
                }

                let data = try await downloadData()
                return data
            } catch {}
        }

        throw "Unable to download the data for \(api.url)"
    }

    private func downloadData() async throws -> Data {
        let data = try await sendRequest(
            url: api.url,
            method: .get,
            headers: api.headers,
            body: nil
        )
        
        return data
    }
}
