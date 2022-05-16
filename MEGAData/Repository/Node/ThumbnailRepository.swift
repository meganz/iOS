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
    
    func hasCachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> Bool {
        switch type {
        case .thumbnail:
            return fileRepo.fileExists(at: fileRepo.cachedThumbnailURL(for: node.base64Handle))
        case .preview:
            return fileRepo.fileExists(at: fileRepo.cachedPreviewURL(for: node.base64Handle))
        }
    }
    
    func cachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL {
        switch type {
        case .thumbnail:
            return fileRepo.cachedThumbnailURL(for: node.base64Handle)
        case .preview:
            return fileRepo.cachedPreviewURL(for: node.base64Handle)
        }
    }
    
    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        let url = cachedThumbnail(for: node, type: type)
        if fileRepo.fileExists(at: url) {
            completion(.success(url))
        } else {
            downloadThumbnail(for: node, type: type, to: url, completion: completion)
        }
    }
    
    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            loadThumbnail(for: node, type: type) {
                continuation.resume(with: $0)
            }
        }
    }
    
    // MARK: - download thumbnail from server
    private func downloadThumbnail(for node: NodeEntity,
                                   type: ThumbnailTypeEntity,
                                   to url: URL,
                                   completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        guard let node = node.toMEGANode(in: sdk) else {
            completion(.failure(.nodeNotFound))
            return
        }
        
        switch type {
        case .thumbnail:
            downloadThumbnail(for: node, to: url, completion: completion)
        case .preview:
            downloadPreview(for: node, to: url, completion: completion)
        }
    }
    
    private func downloadThumbnail(for node: MEGANode, to url: URL, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
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
    
    private func downloadPreview(for node: MEGANode, to url: URL, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
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
