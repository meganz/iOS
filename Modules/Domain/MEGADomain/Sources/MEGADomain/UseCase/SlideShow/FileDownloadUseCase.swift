import Foundation

public protocol FileDownloadUseCaseProtocol: Sendable {
    func cachedOriginalPath(_ node: NodeEntity) -> URL?
    func downloadNode(_ node: NodeEntity) async throws -> URL
}

public struct FileDownloadUseCase<
    T: DownloadFileRepositoryProtocol,
    U: FileSystemRepositoryProtocol,
    V: FileCacheRepositoryProtocol
> {
    
    public let fileCacheRepository: V
    public let fileSystemRepository: U
    public let downloadFileRepository: T
    
    public init(
        fileCacheRepository: V,
        fileSystemRepository: U,
        downloadFileRepository: T
    ) {
        self.fileCacheRepository = fileCacheRepository
        self.fileSystemRepository = fileSystemRepository
        self.downloadFileRepository = downloadFileRepository
    }
}

extension FileDownloadUseCase: FileDownloadUseCaseProtocol {
    
    public func cachedOriginalPath(_ node: NodeEntity) -> URL? {
        fileCacheRepository.existingOriginalImageURL(for: node)
    }
    
    public func downloadNode(_ node: NodeEntity) async throws -> URL {
        if let url = cachedOriginalPath(node) {
            return url
        }
        
        let url = fileCacheRepository.cachedOriginalImageURL(for: node)
        
        guard BatchDownloadFeatureFlag.isEnabled else {
            return try await legacyDownloadNode(node, to: url)
        }
        
        try await downloadFileRepository.download(batch: [
            DownloadBatchItemEntity(
                source: .node(node.handle),
                destination: .file(url),
                startFirst: true
            )
        ])
        
        return url
    }
    
    // MARK: - Private
    private func legacyDownloadNode(_ node: NodeEntity, to url: URL) async throws -> URL {
        let downloadedFile = try await downloadFileRepository.download(
            nodeHandle: node.handle,
            to: url,
            metaData: .none
        )
        
        if let path = downloadedFile.path {
            return URL(fileURLWithPath: path)
        } else {
            throw TransferErrorEntity.download
        }
    }
}
