import Foundation

struct ThumbnailRepository: ThumbnailRepositoryProtocol {
    private let sdk: MEGASdk
    private let fileRepo: FileRepositoryProtocol
    
    init(sdk: MEGASdk, fileRepo: FileRepositoryProtocol) {
        self.sdk = sdk
        self.fileRepo = fileRepo
    }
    
    // MARK: - thumbnail
    func getCachedThumbnail(for handle: MEGAHandle, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        guard let node = sdk.node(forHandle: handle), let base64Handle = node.base64Handle else {
            completion(.failure(.nodeNotFound))
            return
        }
        
        let url = fileRepo.cachedThumbnailURL(forHandle: base64Handle)
        
        if fileRepo.fileExists(at: url) {
            completion(.success(url))
        } else {
            downloadThumbnail(for: node, to: url, completion: completion)
        }
    }
    
    private func downloadThumbnail(for node: MEGANode, to url: URL, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        guard node.hasThumbnail() else {
            completion(.failure(.noThumbnail))
            return
        }
        
        sdk.getThumbnailNode(node, destinationFilePath: url.path, delegate: RequestDelegate { result in
            switch result {
            case .failure(let error):
                switch error.type {
                case .apiENoent:
                    completion(.failure(.noThumbnail))
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
    func getCachedPreview(for handle: MEGAHandle, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        guard let node = sdk.node(forHandle: handle), let base64Handle = node.base64Handle else {
            completion(.failure(.nodeNotFound))
            return
        }
        
        let url = fileRepo.cachedPreviewURL(forHandle: base64Handle)
        
        if fileRepo.fileExists(at: url) {
            completion(.success(url))
        } else {
            downloadPreview(for: node, to: url, completion: completion)
        }
    }
    
    private func downloadPreview(for node: MEGANode, to url: URL, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        guard node.hasPreview() else {
            completion(.failure(.noPreview))
            return
        }
        
        sdk.getPreviewNode(node, destinationFilePath: url.path, delegate: RequestDelegate { result in
            switch result {
            case .failure(let error):
                switch error.type {
                case .apiENoent:
                    completion(.failure(.noPreview))
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
