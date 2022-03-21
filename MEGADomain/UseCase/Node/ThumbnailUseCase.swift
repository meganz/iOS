import Foundation
import Combine

// MARK: - Use case protocol -
protocol ThumbnailUseCaseProtocol {
    func hasCachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> Bool
    func cachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL
    
    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void)
    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> Future<URL, ThumbnailErrorEntity>
    
    func loadThumbnailAndPreview(for node: NodeEntity) -> AnyPublisher<(URL?, URL?), ThumbnailErrorEntity>
    
    /// Load preview and it may publish any available low quality thumbnails before publishing the final preview
    /// - Returns: A publisher that emits URL of thumbnail and preview
    func loadPreview(for node: NodeEntity) -> AnyPublisher<URL, ThumbnailErrorEntity>
    
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
    
    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        switch type {
        case .thumbnail:
            DispatchQueue.global(qos: .utility).async {
                repository.loadThumbnail(for: node, completion: completion)
            }
        case .preview:
            DispatchQueue.global(qos: .utility).async {
                repository.loadPreview(for: node, completion: completion)
            }
        }
    }
    
    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> Future<URL, ThumbnailErrorEntity> {
        Future { promise in
            loadThumbnail(for: node, type: type, completion: promise)
        }
    }
    
    func loadPreview(for node: NodeEntity) -> AnyPublisher<URL, ThumbnailErrorEntity> {
        loadThumbnailAndPreview(for: node)
            .combinePrevious((nil, nil))
            .filter { result in
                result.previous.1 == nil
            }
            .compactMap { result -> URL? in
                if let previewURL = result.current.1 {
                    return previewURL
                } else {
                    return result.current.0
                }
            }
            .eraseToAnyPublisher()
    }
    
    func loadThumbnailAndPreview(for node: NodeEntity) -> AnyPublisher<(URL?, URL?), ThumbnailErrorEntity> {
        loadThumbnail(for: node, type: .thumbnail)
            .map(Optional.some)
            .prepend(nil)
            .combineLatest(
                loadThumbnail(for: node, type: .preview)
                    .map(Optional.some)
                    .prepend(nil)
            )
            .eraseToAnyPublisher()
    }
    
    func thumbnailPlaceholderFileType(forNodeName name: String) -> MEGAFileType {
        fileTypes.fileType(forFileName: name)
    }
}

