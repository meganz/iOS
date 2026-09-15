import Foundation
import MEGADomain
import MEGASwift

public final class MockDownloadFileRepository: DownloadFileRepositoryProtocol, @unchecked Sendable {
    
    public static let newRepo = MockDownloadFileRepository()
    
    private let completionResult: Result<TransferEntity, TransferErrorEntity>
    private let error: TransferErrorEntity
    private let transferEntity: TransferEntity?
    private let folderDownloadResult: Result<FolderDownloadResultEntity, TransferErrorEntity>
    private let downloadBatchResult: Result<[TransferEventEntity], any Error>?
    private let downloadBatchEventsError: (any Error)?

    /// Every batch `downloadProgress(batch:)` was handed, in call order.
    @Atomic public var startedDownloadBatches = [[DownloadBatchItemEntity]]()
    @Atomic public var cancelDownloadTransfers_calledTimes = 0

    /// Fires for every batch handed to `downloadProgress(batch:)`, for a test that has to wait for the
    /// hand over instead of assuming it already happened.
    public var handedOverBatches: AnyAsyncSequence<[DownloadBatchItemEntity]> {
        handOverStream.eraseToAnyAsyncSequence()
    }

    private let handOverStream: AsyncStream<[DownloadBatchItemEntity]>
    private let handOverContinuation: AsyncStream<[DownloadBatchItemEntity]>.Continuation

    /// - Parameters:
    ///   - downloadBatchResult: The events `downloadProgress(batch:)` emits, or the error it throws
    ///     instead of handing the batch over at all. `nil` falls back to `completionResult`.
    ///   - downloadBatchEventsError: An error to end the event sequence with, after the events of
    ///     `downloadBatchResult`.
    public init(completionResult: Result<TransferEntity, TransferErrorEntity> = .failure(.generic),
                error: TransferErrorEntity = .generic,
                transferEntity: TransferEntity? = nil,
                folderDownloadResult: Result<FolderDownloadResultEntity, TransferErrorEntity> = .failure(.generic),
                downloadBatchResult: Result<[TransferEventEntity], any Error>? = nil,
                downloadBatchEventsError: (any Error)? = nil) {
        self.completionResult = completionResult
        self.error = error
        self.transferEntity = transferEntity
        self.folderDownloadResult = folderDownloadResult
        self.downloadBatchResult = downloadBatchResult
        self.downloadBatchEventsError = downloadBatchEventsError
        (handOverStream, handOverContinuation) = AsyncStream.makeStream(of: [DownloadBatchItemEntity].self)
    }

    public func download(nodeHandle: HandleEntity, to url: URL, metaData: TransferMetaDataEntity?) async throws -> TransferEntity {
        try await withCheckedThrowingContinuation { continuation in continuation.resume(with: completionResult) }
    }

    public func downloadFolder(
        nodeHandle: HandleEntity,
        to url: URL,
        metaData: TransferMetaDataEntity?
    ) async throws -> FolderDownloadResultEntity {
        try folderDownloadResult.get()
    }

    public func downloadProgress(batch: [DownloadBatchItemEntity]) -> AnyAsyncThrowingSequence<TransferEventEntity, any Error> {
        $startedDownloadBatches.mutate { $0.append(batch) }
        handOverContinuation.yield(batch)
        let events = downloadBatchEvents()
        let endError = downloadBatchEventsError
        return AsyncThrowingStream(TransferEventEntity.self) { continuation in
            switch events {
            case .success(let events):
                events.forEach { continuation.yield($0) }
                continuation.finish(throwing: endError)
            case .failure(let error):
                continuation.finish(throwing: error)
            }
        }.eraseToAnyAsyncThrowingSequence()
    }

    /// Mirrors the repository: the batch is handed over exactly as `downloadProgress(batch:)` does,
    /// and the call returns on the batch's `finish` or throws what ended the sequence before it.
    public func download(batch: [DownloadBatchItemEntity]) async throws {
        _ = try await downloadProgress(batch: batch).first(where: \.isTerminal)
    }

    public func downloadTo(_ url: URL, nodeHandle: HandleEntity, appData: String?) throws -> AnyAsyncSequence<TransferEventEntity> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }
    
    public func downloadFile(forNodeHandle handle: HandleEntity, to url: URL, filename: String?, appdata: String?, startFirst: Bool) throws -> AnyAsyncSequence<TransferEventEntity> {
        try proceedDownload()
    }
    
    public func downloadFileLink(
        _ fileLink: FileLinkEntity,
        named name: String,
        to url: URL,
        metaData: TransferMetaDataEntity?,
        startFirst: Bool
    ) throws -> AnyAsyncSequence<TransferEventEntity> {
        try proceedDownload()
    }
    
    public func cancelDownloadTransfers() {
        $cancelDownloadTransfers_calledTimes.mutate { $0 += 1 }
    }
    
    // MARK: Private
    private func downloadBatchEvents() -> Result<[TransferEventEntity], any Error> {
        if let downloadBatchResult {
            return downloadBatchResult
        }
        return switch completionResult {
        case .success(let transferEntity):
            .success([.start(transferEntity), .update(transferEntity), .finish(transferEntity)])
        case .failure(let error):
            .failure(error)
        }
    }

    private func proceedDownload() throws -> AnyAsyncSequence<TransferEventEntity> {
        switch completionResult {
        case .success(let transferEntity):
            AsyncThrowingStream(TransferEventEntity.self) { continuation in
                continuation.yield(.start(transferEntity))
                continuation.yield(.update(transferEntity))
                continuation.yield(.finish(transferEntity))
                continuation.finish()
            }.eraseToAnyAsyncSequence()
        case .failure(let error):
            throw error
        }
    }
}
