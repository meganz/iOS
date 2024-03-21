import Foundation
import MEGAFoundation
import MEGASwiftUI

public struct MockURLSession: URLSessionProtocol {
    private var mockData: Data?
    private let mockError: (any Error)?
    
    public init(
        mockData: Data? = nil,
        mockError: (any Error)? = nil
    ) {
        self.mockData = mockData
        self.mockError = mockError
    }
    
    public func fetchData(from url: URL) async throws -> (Data, URLResponse) {
        if let error = mockError {
            throw error
        }
        if let data = mockData {
            return (data, URLResponse(url: url, mimeType: nil, expectedContentLength: Int(data.count), textEncodingName: nil))
        }
        throw NSError(domain: "MockError", code: 0, userInfo: nil)
    }
    
    public mutating func resetData() {
        mockData = nil
    }
    
    public mutating func updateCurrentData(_ data: Data) {
        mockData = data
    }
}
