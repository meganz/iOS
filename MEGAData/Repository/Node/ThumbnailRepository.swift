import Foundation

extension ThumbnailRepository {
    static let `default` = ThumbnailRepository(sdk: MEGASdkManager.sharedMEGASdk(), fileManager: .default)
}

struct ThumbnailRepository: ThumbnailRepositoryProtocol {
    private enum Constants {
        static let thumbnailCacheDirectory = "thumbnailsV3"
        static let previewCacheDirectory = "previewsV3"
    }
    
    private let sdk: MEGASdk
    private let fileManager: FileManager
    private let groupContainer: AppGroupContainer
    private let appGroupCacheURL: URL
    
    init(sdk: MEGASdk, fileManager: FileManager) {
        self.sdk = sdk
        self.fileManager = fileManager
        groupContainer = AppGroupContainer(fileManager: fileManager)
        appGroupCacheURL = groupContainer.url(for: .cache)
    }
    
    func hasCachedThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity) -> Bool {
        fileExists(at: cachedThumbnailURL(for: node.base64Handle, type: type))
    }
    
    func cachedThumbnailURL(for node: NodeEntity, type: ThumbnailTypeEntity) -> URL {
        cachedThumbnailURL(for: node.base64Handle, type: type)
    }
    
    func loadThumbnail(for node: NodeEntity, type: ThumbnailTypeEntity, completion: @escaping (Result<URL, ThumbnailErrorEntity>) -> Void) {
        let url = cachedThumbnailURL(for: node, type: type)
        if fileExists(at: url) {
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
    
    func cachedThumbnailURL(for base64Handle: MEGABase64Handle, type: ThumbnailTypeEntity) -> URL {
        let directory: String
        switch type {
        case .thumbnail:
            directory = Constants.thumbnailCacheDirectory
        case .preview:
            directory = Constants.previewCacheDirectory
        }
        
        let directoryURL = appGroupCacheURL.appendingPathComponent(directory, isDirectory: true)
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL.appendingPathComponent(base64Handle)
    }
}

// MARK: - download thumbnail from remote -
extension ThumbnailRepository {
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

extension ThumbnailRepository {
    private func fileExists(at url: URL) -> Bool {
        fileManager.fileExists(atPath: url.path)
    }
}
