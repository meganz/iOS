@testable import MEGA
import Combine

struct MockThumbnailUseCase<T: ThumbnailRepositoryProtocol>: ThumbnailUseCaseProtocol {
    var placeholderFileType: MEGAFileType = "generic"
    var mockThumbnailRepo: T
    
    init(repo: T) {
        mockThumbnailRepo = repo
    }
    
    func hasCachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> Bool {
        switch type {
        case .thumbnail:
            return mockThumbnailRepo.hasCachedThumbnail(for: node)
        case .preview:
            return mockThumbnailRepo.hasCachedPreview(for: node)
        }
    }
    
    func cachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL {
        switch type {
        case .thumbnail:
            return mockThumbnailRepo.cachedThumbnail(for: node)
        case .preview:
            return mockThumbnailRepo.cachedPreview(for: node)
        }
    }
    
    func loadThumbnail(for node: NodeEntity) async throws -> URL {
        return try await mockThumbnailRepo.loadThumbnail(for: node)
    }
    
    func loadPreview(for node: NodeEntity) -> PreviewLoading {
        return PreviewLoading(types: [.thumbnail, .preview], node: node, repo: mockThumbnailRepo)
    }
    
    func thumbnailPlaceholderFileType(forNodeName: String) -> MEGAFileType {
        placeholderFileType
    }
}
