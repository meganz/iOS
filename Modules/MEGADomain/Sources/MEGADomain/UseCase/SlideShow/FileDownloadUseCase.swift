import Foundation

public protocol FileDownloadUseCaseProtocol {
    func cachedOriginalPath(_ node: NodeEntity) -> URL?
    func downloadNode(_ node: NodeEntity) async throws -> URL
}

public struct FileDownloadUseCase<T:DownloadFileRepositoryProtocol,
                              U:FileSystemRepositoryProtocol,
                              V:FileCacheRepositoryProtocol> {
    
    public let fileCacheRepository: V
    public let fileSystemRepository: U
    public let downloadFileRepository: T
    
    public init(fileCacheRepository: V,
         fileSystemRepository: U,
         downloadFileRepository: T) {
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
        try await withCheckedThrowingContinuation { continuation in
            if let url = cachedOriginalPath(node) {
                continuation.resume(returning: url)
                return
            }
            if fileSystemRepository.systemVolumeAvailability() < node.size {
                continuation.resume(throwing: ExportFileErrorEntity.notEnoughSpace)
                return
            }
            let url = fileCacheRepository.cachedOriginalImageURL(for: node)
            downloadFileRepository.download(nodeHandle: node.handle, to: url, metaData: .none) { result in
                switch result {
                case .success(let transferEntity):
                    guard let path = transferEntity.path else { return }
                    let url = URL(fileURLWithPath: path)
                    continuation.resume(returning: url)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
