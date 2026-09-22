import Foundation
import MEGADomain
import MEGASwift

public final class MockUploadFileRepository: UploadFileRepositoryProtocol, @unchecked Sendable {

    public static let newRepo = MockUploadFileRepository()

    private let hasExistFile: Bool
    private let resolvedFileName: String?
    private let uploadResult: Result<TransferEntity, TransferErrorEntity>
    private let batchEvents: [TransferEventEntity]
    private let batchEventsError: (any Error)?

    /// Every batch `upload(batch:)` was handed, in call order.
    @Atomic public var uploadedBatches = [[UploadBatchItemEntity]]()
    @Atomic public var cancelUploadTransfers_calledTimes = 0

    /// Fires for every batch handed to `upload(batch:)`, for a test that has to wait for the hand
    /// over instead of assuming it already happened.
    public var handedOverBatches: AnyAsyncSequence<[UploadBatchItemEntity]> {
        handOverStream.eraseToAnyAsyncSequence()
    }

    private let handOverStream: AsyncStream<[UploadBatchItemEntity]>
    private let handOverContinuation: AsyncStream<[UploadBatchItemEntity]>.Continuation

    /// - Parameters:
    ///   - uploadResult: What a single file upload ends with.
    ///   - batchEvents: The events `upload(batch:)` reports, in order, before finishing.
    ///   - batchEventsError: An error to end `upload(batch:)` with, after `batchEvents`.
    public init(
        hasExistFile: Bool = false,
        resolvedFileName: String? = nil,
        uploadResult: Result<TransferEntity, TransferErrorEntity> = .failure(.upload),
        batchEvents: [TransferEventEntity] = [],
        batchEventsError: (any Error)? = nil
    ) {
        self.hasExistFile = hasExistFile
        self.resolvedFileName = resolvedFileName
        self.uploadResult = uploadResult
        self.batchEvents = batchEvents
        self.batchEventsError = batchEventsError
        (handOverStream, handOverContinuation) = AsyncStream.makeStream(of: [UploadBatchItemEntity].self)
    }

    public func hasExistFile(name: String, parentHandle: HandleEntity) -> Bool {
        hasExistFile
    }

    public func resolvedFileName(_ name: String, inParent parentHandle: HandleEntity) async -> String {
        resolvedFileName ?? name
    }

    public func uploadFile(
        _ url: URL,
        toParent parent: HandleEntity,
        uploadOptions: UploadOptionsEntity,
        start: ((TransferEntity) -> Void)?,
        progress: ((TransferEntity) -> Void)?,
        temporaryError: ((TransferEntity, ErrorEntity) -> Void)?,
        completion: ((Result<TransferEntity, TransferErrorEntity>) -> Void)?
    ) {
        completion?(uploadResult)
    }

    public func uploadFile(
        _ url: URL,
        toParent parent: HandleEntity,
        uploadOptions: UploadOptionsEntity,
        start: ((TransferEntity) -> Void)?,
        progress: ((TransferEntity) -> Void)?
    ) async throws -> TransferEntity {
        try uploadResult.get()
    }

    public func uploadSupportFile(_ url: URL) async throws -> AnyAsyncSequence<FileUploadEvent> {
        EmptyAsyncSequence().eraseToAnyAsyncSequence()
    }

    public func upload(batch: [UploadBatchItemEntity]) -> AnyAsyncThrowingSequence<TransferEventEntity, any Error> {
        $uploadedBatches.mutate { $0.append(batch) }
        handOverContinuation.yield(batch)
        let events = batchEvents
        let endError = batchEventsError

        return AsyncThrowingStream(TransferEventEntity.self) { continuation in
            events.forEach { continuation.yield($0) }
            continuation.finish(throwing: endError)
        }.eraseToAnyAsyncThrowingSequence()
    }

    public func cancel(transfer: TransferEntity) async throws { }

    public func cancelUploadTransfers() {
        $cancelUploadTransfers_calledTimes.mutate { $0 += 1 }
    }
}
