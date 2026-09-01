import MEGADomain
import MEGASwift

public final class MockDownloadNodeUseCase: DownloadNodeUseCaseProtocol, @unchecked Sendable {
    private let transferEntity: TransferEntity?
    private let folderUpdateEntity: FolderTransferUpdateEntity?
    private let result: (Result<TransferEntity, TransferErrorEntity>)?
    
    /// Records the nodes asked for by entity, which is the only way to tell an already resolved source --
    /// a public album link's photos -- apart from an ordinary lookup by handle.
    @Atomic public var downloadedNodes: [NodeEntity] = []
    
    public init(transferEntity: TransferEntity? = nil,
                folderUpdateEntity: FolderTransferUpdateEntity? = nil,
                result: Result<TransferEntity, TransferErrorEntity>? = nil) {
        self.transferEntity = transferEntity
        self.folderUpdateEntity = folderUpdateEntity
        self.result = result
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

    public func downloadFileToTempFolder(nodeHandle: HandleEntity, appData: String?) throws -> AnyAsyncSequence<TransferEventEntity> {
        try proceedDownload()
    }
        
    public func downloadFileLinkToOffline(_ fileLink: FileLinkEntity, filename: String?, metaData: TransferMetaDataEntity?, startFirst: Bool) async throws -> AnyAsyncSequence<TransferEventEntity> {
        try proceedDownload()
    }
    
    public func cancelDownloadTransfers() { }
    
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
