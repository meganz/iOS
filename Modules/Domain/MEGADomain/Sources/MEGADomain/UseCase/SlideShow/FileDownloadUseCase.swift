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
