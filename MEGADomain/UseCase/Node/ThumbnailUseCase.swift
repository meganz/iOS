import Foundation
import Combine

// MARK: - Use case protocol -
protocol ThumbnailUseCaseProtocol {
    func hasCachedThumbnail(for node: NodeEntity) -> Bool
    func hasCachedPreview(for node: NodeEntity) -> Bool
    func cachedThumbnail(for node: NodeEntity) -> URL
    func cachedPreview(for node: NodeEntity) -> URL
    
    func loadThumbnail(for node: NodeEntity, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void)
    func loadThumbnail(for node: NodeEntity) -> Future<URL, ThumbnailErrorEntity>
    func loadPreview(for node: NodeEntity, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void)
    func loadPreview(for node: NodeEntity) -> Future<URL, ThumbnailErrorEntity>
    func loadThumbnailAndPreview(for node: NodeEntity) -> AnyPublisher<(URL?, URL?), ThumbnailErrorEntity>
    
    func thumbnailPlaceholderFileType(forNodeName name: String) -> MEGAFileType
}

extension ThumbnailUseCase {
    static let `default` = ThumbnailUseCase(repository: ThumbnailRepository.default)
}

struct ThumbnailUseCase: ThumbnailUseCaseProtocol {
    private let repository: ThumbnailRepositoryProtocol
    private let fileTypes = FileTypes()
    
    init(repository: ThumbnailRepositoryProtocol) {
        self.repository = repository
    }
    
    func hasCachedThumbnail(for node: NodeEntity) -> Bool {
        repository.hasCachedThumbnail(for: node)
    }
    
    func hasCachedPreview(for node: NodeEntity) -> Bool {
        repository.hasCachedPreview(for: node)
    }
    
    func cachedThumbnail(for node: NodeEntity) -> URL {
        repository.cachedThumbnail(for: node)
    }
    
    func cachedPreview(for node: NodeEntity) -> URL {
        repository.cachedPreview(for: node)
    }
    
    func loadThumbnail(for node: NodeEntity, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            repository.loadThumbnail(for: node, completion: completion)
        }
    }
    
    func loadThumbnail(for node: NodeEntity) -> Future<URL, ThumbnailErrorEntity> {
        Future { promise in
            loadThumbnail(for: node, completion: promise)
        }
    }
    
    func loadPreview(for node: NodeEntity, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            repository.loadPreview(for: node, completion: completion)
        }
    }
    
    func loadPreview(for node: NodeEntity) -> Future<URL, ThumbnailErrorEntity> {
        Future { promise in
            loadPreview(for: node, completion: promise)
        }
    }
    
    func loadThumbnailAndPreview(for node: NodeEntity) -> AnyPublisher<(URL?, URL?), ThumbnailErrorEntity> {
        loadThumbnail(for: node)
            .map(Optional.some)
            .prepend(nil)
            .combineLatest(
                loadPreview(for: node)
                    .map(Optional.some)
                    .prepend(nil)
            )
            .eraseToAnyPublisher()
    }
    
    func thumbnailPlaceholderFileType(forNodeName name: String) -> MEGAFileType {
        fileTypes.fileType(forFileName: name)
    }
}

