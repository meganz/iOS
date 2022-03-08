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
    
    // MARK: - thumbnail
    func hasCachedThumbnail(for node: NodeEntity) -> Bool {
        fileRepo.fileExists(at: fileRepo.cachedThumbnailURL(for: node.base64Handle))
    }
    
    func cachedThumbnail(for node: NodeEntity) -> URL {
        fileRepo.cachedThumbnailURL(for: node.base64Handle)
    }
    
    func loadThumbnail(for node: NodeEntity, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        let url = cachedThumbnail(for: node)
        if fileRepo.fileExists(at: url) {
            completion(.success(url))
        } else {
            downloadThumbnail(for: node, to: url, completion: completion)
        }
    }
    
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
    
    // MARK: - preview
    func hasCachedPreview(for node: NodeEntity) -> Bool {
        fileRepo.fileExists(at: fileRepo.cachedPreviewURL(for: node.base64Handle))
    }
    
    func cachedPreview(for node: NodeEntity) -> URL {
        fileRepo.cachedPreviewURL(for: node.base64Handle)
    }
    
    func loadPreview(for node: NodeEntity, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        let url = cachedPreview(for: node)
        if fileRepo.fileExists(at: url) {
            completion(.success(url))
        } else {
            downloadPreview(for: node, to: url, completion: completion)
        }
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
