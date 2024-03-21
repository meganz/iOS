import Foundation

public protocol URLSessionProtocol {
    func fetchData(from url: URL) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {
    public func fetchData(from url: URL) async throws -> (Data, URLResponse) {
        return try await self.data(from: url)
    }
}
