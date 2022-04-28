import Foundation

extension ThumbnailRepository {
    static let `default` = ThumbnailRepository(sdk: MEGASdkManager.sharedMEGASdk(), fileRepo: FileSystemRepository.default)
}

struct ThumbnailRepository: ThumbnailRepositoryProtocol {
    private let sdk: MEGASdk
    private let fileRepo: FileRepositoryProtocol
    
    init(sdk: MEGASdk, fileRepo: FileRepositoryProtocol) {
        self.sdk = sdk
        self.fileRepo = fileRepo
    }
    
    // MARK: - Thumbnail
    
    func hasCachedThumbnail(for node: NodeEntity) -> Bool {
        fileRepo.fileExists(at: fileRepo.cachedThumbnailURL(for: node.base64Handle))
    }
    
    func cachedThumbnail(for node: NodeEntity) -> URL {
        fileRepo.cachedThumbnailURL(for: node.base64Handle)
    }
    
    func loadThumbnail(for node: NodeEntity) async throws -> URL {
        let url = cachedThumbnail(for: node)
        
        if fileRepo.fileExists(at: url) {
            return url
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                downloadThumbnail(for: node, to: url) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }
    
    // MARK: - Preview
    
    func hasCachedPreview(for node: NodeEntity) -> Bool {
        fileRepo.fileExists(at: fileRepo.cachedPreviewURL(for: node.base64Handle))
    }
    
    func cachedPreview(for node: NodeEntity) -> URL {
        fileRepo.cachedPreviewURL(for: node.base64Handle)
    }
    
    func loadPreview(for node: NodeEntity) async throws -> URL {
        let url = cachedPreview(for: node)
        
        if fileRepo.fileExists(at: url) {
            return url
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                downloadPreview(for: node, to: url) { result in
                    continuation.resume(with: result)
                }
            }
        }
    }
    
    
    // MARK: - Private
    
    private func downloadThumbnail(for node: NodeEntity, to url: URL, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        guard let node = node.toMEGANode(in: sdk) else {
            completion(.failure(.nodeNotFound))
            return
        }
        
        guard node.hasThumbnail() else {
            completion(.failure(.noThumbnail(.thumbnail)))
            return
        }
        
        sdk.getThumbnailNode(node, destinationFilePath: url.path, delegate: RequestDelegate { result in
            switch result {
            case .failure(let error):
                switch error.type {
                case .apiENoent:
                    completion(.failure(.noThumbnail(.thumbnail)))
                default:
                    completion(.failure(.generic))
                }
            case .success(let request):
                if let url = request.toFileURL() {
                    completion(.success(url))
                } else {
                    completion(.failure(.generic))
                }
            }
        })
    }
    
    private func downloadPreview(for node: NodeEntity, to url: URL, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        guard let node = node.toMEGANode(in: sdk) else {
            completion(.failure(.nodeNotFound))
            return
        }
        
        guard node.hasPreview() else {
            completion(.failure(.noThumbnail(.preview)))
            return
        }
        
        sdk.getPreviewNode(node, destinationFilePath: url.path, delegate: RequestDelegate { result in
            switch result {
            case .failure(let error):
                switch error.type {
                case .apiENoent:
                    completion(.failure(.noThumbnail(.preview)))
                default:
                    completion(.failure(.generic))
                }
            case .success(let request):
                if let url = request.toFileURL() {
                    completion(.success(url))
                } else {
                    completion(.failure(.generic))
                }
            }
        })
    }
}
