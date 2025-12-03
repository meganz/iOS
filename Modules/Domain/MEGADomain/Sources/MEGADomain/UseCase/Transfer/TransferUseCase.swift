import Foundation
import MEGASwift

public protocol TransferUseCaseProtocol: Sendable {
    /// Downloads a node to a local URL with optional handlers for transfer events.
    ///
    /// This method initiates a download and uses closures to notify about transfer start and progress.
    /// The method completes when the download finishes, returning the final transfer entity.
    ///
    /// - Parameters:
    ///   - node: The node entity to download from the cloud storage.
    ///   - localUrl: The local file system URL where the node should be downloaded.
    ///   - collisionResolution: The strategy to use when a file already exists at the destination.
    ///   - startHandler: An optional closure called when the download starts, passing the initial transfer entity.
    ///   - progressHandler: An optional closure called periodically during the download with updated transfer progress.
    /// - Returns: The completed transfer entity with final transfer information.
    /// - Throws: An error if the download fails or cannot be initiated.
    func download(
        node: NodeEntity,
        to localUrl: URL,
        collisionResolution: CollisionResolutionEntity,
        startHandler: ((TransferEntity) -> Void)?,
        progressHandler: ((TransferEntity) -> Void)?
    ) async throws -> TransferEntity
    
    /// Downloads a node to a local URL and returns an async sequence of transfer events.
    ///
    /// This method initiates a download and returns an async sequence that emits transfer events
    /// throughout the download lifecycle, including start, progress updates, and completion.
    ///
    /// - Parameters:
    ///   - node: The node entity to download from the cloud storage.
    ///   - localUrl: The local file system URL where the node should be downloaded.
    ///   - collisionResolution: The strategy to use when a file already exists at the destination.
    /// - Returns: An async sequence that emits `TransferEventEntity` events during the download.
    /// - Throws: An error if the download cannot be initiated.
    func download(
        node: NodeEntity,
        to localUrl: URL,
        collisionResolution: CollisionResolutionEntity
    ) throws -> AnyAsyncSequence<TransferEventEntity>
    
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
    
    public func download(
        node: NodeEntity,
        to localUrl: URL,
        collisionResolution: CollisionResolutionEntity
    ) throws -> AnyAsyncSequence<TransferEventEntity> {
        try repo.download(
            node: node,
            to: localUrl,
            collisionResolution: collisionResolution
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
