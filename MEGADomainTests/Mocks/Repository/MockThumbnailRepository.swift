import Foundation
@testable import MEGA

struct MockThumbnailRepository: ThumbnailRepositoryProtocol {
    var mockResult: URL?
    var mockError: ThumbnailErrorEntity?
    
    
    func hasCachedThumbnail(for node: NodeEntity) -> Bool {
        return true
    }
    
    func hasCachedPreview(for node: NodeEntity) -> Bool {
        return true
    }
    
    func cachedThumbnail(for node: NodeEntity) -> URL {
        return URL(string: "https://MEGA.NZ")!
    }
    
    func cachedPreview(for node: NodeEntity) -> URL {
        return URL(string: "https://MEGA.NZ")!
    }
    
    func loadThumbnail(for node: NodeEntity) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            if let mockResult = mockResult {
                return continuation.resume(returning: mockResult)
            } else if let error = mockError {
                return continuation.resume(throwing: error)
            } else {
                return continuation.resume(throwing: ThumbnailErrorEntity.generic)
            }
        }
    }
    
    func loadPreview(for node: NodeEntity) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            if let mockResult = mockResult {
                return continuation.resume(returning: mockResult)
            } else if let error = mockError {
                return continuation.resume(throwing: error)
            } else {
                return continuation.resume(throwing: ThumbnailErrorEntity.generic)
            }
        }
    }
}
