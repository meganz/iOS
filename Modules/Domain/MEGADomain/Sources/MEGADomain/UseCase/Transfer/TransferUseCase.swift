import Foundation

public protocol TransferUseCaseProtocol: Sendable {
    func download(
        node: NodeEntity,
        to localUrl: URL,
        collisionResolution: CollisionResolutionEntity,
        startHandler: ((TransferEntity) -> Void)?,
        progressHandler: ((TransferEntity) -> Void)?
    ) async throws -> TransferEntity
    func uploadFile(at fileUrl: URL, to parent: NodeEntity, startHandler: ((TransferEntity) -> Void)?, progressHandler: ((TransferEntity) -> Void)?) async throws -> TransferEntity
    func cancelDownloadTransfers() async throws
    func cancelUploadTransfers() async throws
}

public struct TransferUseCase<T: TransferRepositoryProtocol, M: MetadataUseCaseProtocol, N: NodeDataRepositoryProtocol>: TransferUseCaseProtocol {
    
    private let repo: T
    private let metadataUseCase: M
    private let nodeDataRepository: N
    
    public init(
        repo: T,
        metadataUseCase: M,
        nodeDataRepository: N
    ) {
        self.repo = repo
        self.metadataUseCase = metadataUseCase
        self.nodeDataRepository = nodeDataRepository
    }
    
    public func download(
        node: NodeEntity,
        to localUrl: URL,
        collisionResolution: CollisionResolutionEntity = .renameNewWithSuffix,
        startHandler: ((TransferEntity) -> Void)? = nil,
        progressHandler: ((TransferEntity) -> Void)? = nil
    ) async throws -> TransferEntity {
        try await repo.download(
            node: node,
            to: localUrl,
            collisionResolution: collisionResolution,
            startHandler: startHandler,
            progressHandler: progressHandler
        )
    }
    
    public func uploadFile(at fileUrl: URL, to parent: NodeEntity, startHandler: ((TransferEntity) -> Void)? = nil, progressHandler: ((TransferEntity) -> Void)? = nil) async throws -> TransferEntity {
        let coordinate = await metadataUseCase.coordinateInTheFile(at: fileUrl)
        let transferEntity = try await repo.uploadFile(at: fileUrl, to: parent, startHandler: startHandler, progressHandler: progressHandler)
        
        if let latitude = coordinate?.latitude,
           let longitude = coordinate?.longitude,
           let node = await nodeDataRepository.nodeForHandle(transferEntity.nodeHandle) {
            try await metadataUseCase.setUnshareableNodeCoordinates(node, latitude: latitude, longitude: longitude)
        }
        return transferEntity
    }
    
    public func cancelDownloadTransfers() async throws {
        try await repo.cancelDownloadTransfers()
    }
    
    public func cancelUploadTransfers() async throws {
        try await repo.cancelUploadTransfers()
    }
}
