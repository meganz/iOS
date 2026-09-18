import MEGADomain
import MEGASwift

public final class MockDownloadNodeUseCase: DownloadNodeUseCaseProtocol, @unchecked Sendable {
    private let transferEntity: TransferEntity?
    private let folderUpdateEntity: FolderTransferUpdateEntity?
    private let result: (Result<TransferEntity, TransferErrorEntity>)?
    private let transferEvents: [TransferEventEntity]?
    
    /// Records the nodes asked for by entity, which is the only way to tell an already resolved source --
    /// a public album link's photos, or a link's node being previewed -- apart from an ordinary lookup by handle.
    @Atomic public var downloadedNodes: [NodeEntity] = []
    @Atomic public var cancelDownloadTransfers_calledTimes = 0
    
    /// - Parameter transferEvents: The exact events every download emits, for a caller that has to see an
    ///   event `result` cannot express, such as a temporary error. `nil` falls back to `result`.
    public init(transferEntity: TransferEntity? = nil,
                folderUpdateEntity: FolderTransferUpdateEntity? = nil,
                result: Result<TransferEntity, TransferErrorEntity>? = nil,
                transferEvents: [TransferEventEntity]? = nil) {
        self.transferEntity = transferEntity
        self.folderUpdateEntity = folderUpdateEntity
        self.result = result
        self.transferEvents = transferEvents
    }
    
    public func downloadFileToOffline(
        forNodeHandle handle: HandleEntity,
        filename: String?,
        appData: String?,
        startFirst: Bool
    ) throws -> AnyAsyncSequence<TransferEventEntity> {
        try proceedDownload()
    }
    
    public func downloadFileToOffline(
        _ node: NodeEntity,
        filename: String?,
        appData: String?,
        startFirst: Bool
    ) throws -> AnyAsyncSequence<TransferEventEntity> {
        $downloadedNodes.mutate { $0.append(node) }
        return try proceedDownload()
    }

    public func downloadFileToTempFolder(node: NodeEntity, appData: String?) throws -> AnyAsyncSequence<TransferEventEntity> {
        $downloadedNodes.mutate { $0.append(node) }
        return try proceedDownload()
    }
        
    public func downloadFileLinkToOffline(_ fileLink: FileLinkEntity, filename: String?, metaData: TransferMetaDataEntity?, startFirst: Bool) async throws -> AnyAsyncSequence<TransferEventEntity> {
        try proceedDownload()
    }
    
    public func cancelDownloadTransfers() {
        $cancelDownloadTransfers_calledTimes.mutate { $0 += 1 }
    }
    
    public func downloadChatFileToOffline(
        forNodeHandle handle: HandleEntity,
        messageId: HandleEntity,
        chatId: HandleEntity,
        filename: String?,
        appdata: String?,
        startFirst: Bool
    ) throws -> AnyAsyncSequence<TransferEventEntity> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
    
    // MARK: Private
    private func proceedDownload() throws -> AnyAsyncSequence<TransferEventEntity> {
        if let transferEvents {
            return AsyncStream(TransferEventEntity.self) { continuation in
                transferEvents.forEach { continuation.yield($0) }
                continuation.finish()
            }.eraseToAnyAsyncSequence()
        }
        
        guard let result else {
            return EmptyAsyncSequence().eraseToAnyAsyncSequence()
        }
        
        switch result {
        case .success(let transferEntity):
            return AsyncThrowingStream(TransferEventEntity.self) { continuation in
                continuation.yield(.start(transferEntity))
                continuation.yield(.update(transferEntity))
                if let folderUpdateEntity {
                    continuation.yield(.folderUpdate(folderUpdateEntity))
                }
                continuation.yield(.finish(transferEntity))
                continuation.finish()
            }.eraseToAnyAsyncSequence()
        case .failure(let error):
            throw error
        }
    }
}
