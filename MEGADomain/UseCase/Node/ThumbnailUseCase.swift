import Foundation
import Combine

// MARK: - Use case protocol -
protocol ThumbnailUseCaseProtocol {
    func hasCachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> Bool
    func cachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL
    
    func loadThumbnail(for node: NodeEntity) async throws -> URL
    func loadPreview(for node: NodeEntity) -> PreviewLoading
    func thumbnailPlaceholderFileType(forNodeName name: String) -> MEGAFileType
}

extension ThumbnailUseCase where T == ThumbnailRepository {
    static let `default` = ThumbnailUseCase(repository: T.default)
}

struct ThumbnailUseCase<T: ThumbnailRepositoryProtocol>: ThumbnailUseCaseProtocol {
    private let repository: T
    private let fileTypes = FileTypes()
    
    init(repository: T) {
        self.repository = repository
    }
    
    func hasCachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> Bool {
        switch type {
        case .thumbnail:
            return repository.hasCachedThumbnail(for: node)
        case .preview:
            return repository.hasCachedPreview(for: node)
        }
    }
    
    func cachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL {
        switch type {
        case .thumbnail:
            return repository.cachedThumbnail(for: node)
        case .preview:
            return repository.cachedPreview(for: node)
        }
    }
    
    func loadThumbnail(for node: NodeEntity) async throws -> URL {
        try Task.checkCancellation()
        
        return try await repository.loadThumbnail(for: node)
    }
    
    func loadPreview(for node: NodeEntity) -> PreviewLoading {
        return PreviewLoading(types: [.thumbnail, .preview],
                              node: node,
                              repo: repository)
    }
    
    func thumbnailPlaceholderFileType(forNodeName name: String) -> MEGAFileType {
        fileTypes.fileType(forFileName: name)
    }
}
