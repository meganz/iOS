import MEGASwift

public protocol CameraUploadProgressUseCaseProtocol: Sendable {
    /// Provides an asynchronous sequence that emits updates to asset upload phase changes.
    ///
    /// Each element in the sequence is a `CameraUploadPhaseEventEntity` representing
    /// a transition in the upload phase of a specific asset.
    ///
    /// For example, an event is emitted when:
    /// - An asset is registered for upload
    /// - Uploading starts
    /// - Upload completes (success or failure)
    ///
    /// - Returns: An asynchronous sequence of upload phase events.
    var cameraUploadPhaseEventUpdates: AnyAsyncSequence<CameraUploadPhaseEventEntity> { get async }
    
    /// A single consistent snapshot of the uploading DB records, partitioned in one pass into:
    /// - `inProgress`: files that have transferred at least one byte, resolved to file details, and
    /// - `pending`: uploads handed to the background transfer system but not yet transferring.
    ///
    /// The record set and each record's progress are read exactly once, so both partitions come
    /// from the same snapshot — no duplicate DB/progress work, and no race where a record crossing
    /// the 0→>0 byte boundary ends up in both lists or in neither.
    func inProgressAndPendingFiles() async throws -> (inProgress: [CameraUploadFileDetailsEntity], pending: [CameraAssetUploadEntity])
    
    /// Gets the current upload progress for a specific asset.
    ///
    /// - Parameter localIdentifier: The local identifier of the asset to get progress for.
    /// - Returns: A `CameraUploadProgressEntity` representing the current progress of the upload.
    func uploadProgress(for localIdentifier: CameraUploadLocalIdentifierEntity) async -> CameraUploadProgressEntity
    
    /// Provides an asynchronous sequence that emits progress updates for a specific upload.
    ///
    /// - Parameter localIdentifier: The local identifier of the asset to track progress for.
    /// - Returns: An asynchronous sequence emitting `CameraUploadProgressEntity` values representing the progress updates of the upload.
    func uploadProgressUpdates(for localIdentifier: CameraUploadLocalIdentifierEntity) async -> AnyAsyncSequence<CameraUploadProgressEntity>
}

public struct CameraUploadProgressUseCase: CameraUploadProgressUseCaseProtocol {
    private let cameraUploadAssetRepository: any CameraUploadAssetRepositoryProtocol
    private let transferProgressRepository: any CameraUploadTransferProgressRepositoryProtocol
    
    public init(
        cameraUploadAssetRepository: some CameraUploadAssetRepositoryProtocol,
        transferProgressRepository: some CameraUploadTransferProgressRepositoryProtocol
    ) {
        self.cameraUploadAssetRepository = cameraUploadAssetRepository
        self.transferProgressRepository = transferProgressRepository
    }
    
    public var cameraUploadPhaseEventUpdates: AnyAsyncSequence<CameraUploadPhaseEventEntity> {
        get async {
            await transferProgressRepository.cameraUploadPhaseEventUpdates
        }
    }
    
    public func inProgressAndPendingFiles() async throws -> (inProgress: [CameraUploadFileDetailsEntity], pending: [CameraAssetUploadEntity]) {
        let uploadingRecords = try await uploadingRecords()
        try Task.checkCancellation()

        // Partition the single record set by a single progress read per record: transferred bytes
        // → in progress, otherwise → pending. Reading once keeps the two lists mutually exclusive.
        var transferredIdentifiers: [CameraUploadLocalIdentifierEntity] = []
        var pending: [CameraAssetUploadEntity] = []
        for record in uploadingRecords {
            let progressData = await transferProgressRepository.progressRawData(for: record.localIdentifier)
            if progressData.totalBytesSent > 0 {
                transferredIdentifiers.append(record.localIdentifier)
            } else {
                pending.append(record)
            }
        }
        try Task.checkCancellation()

        let inProgress = try await fileDetails(forOrderedIdentifiers: transferredIdentifiers)
        return (inProgress, pending)
    }
    
    public func uploadProgress(for localIdentifier: CameraUploadLocalIdentifierEntity) async -> CameraUploadProgressEntity {
        let rawData = await transferProgressRepository.progressRawData(for: localIdentifier)
        return calculateProgress(for: rawData)
    }
    
    public func uploadProgressUpdates(for localIdentifier: CameraUploadLocalIdentifierEntity) async -> AnyAsyncSequence<CameraUploadProgressEntity> {
        await transferProgressRepository.progressRawDataUpdates(for: localIdentifier)
            .map(calculateProgress)
            .eraseToAnyAsyncSequence()
    }
    
    private func calculateProgress(for rawData: CameraUploadTaskProgressRawDataEntity) -> CameraUploadProgressEntity {
        let totalBytesExpected = rawData.totalBytesExpected
        let rawProgress = if totalBytesExpected > 0 {
            Double(rawData.totalBytesSent) / Double(totalBytesExpected)
        } else {
            0.0
        }
        return CameraUploadProgressEntity(
            percentage: min(max(rawProgress, 0.0), 1.0),
            totalBytes: totalBytesExpected,
            bytesPerSecond: calculateBytesPerSecond(for: rawData.speedSamples))
    }

    private func uploadingRecords() async throws -> [CameraAssetUploadEntity] {
        try await cameraUploadAssetRepository.uploads(
            startingFrom: nil,
            isForward: true,
            limit: nil,
            statuses: [.uploading],
            mediaTypes: [.image, .video])
    }

    private func fileDetails(
        forOrderedIdentifiers identifiers: [CameraUploadLocalIdentifierEntity]
    ) async throws -> [CameraUploadFileDetailsEntity] {
        guard !identifiers.isEmpty else { return [] }
        let details = try await cameraUploadAssetRepository.fileDetails(forLocalIdentifiers: Set(identifiers))
        try Task.checkCancellation()
        let detailsMap = Dictionary(uniqueKeysWithValues: details.map { ($0.localIdentifier, $0) })
        return identifiers.compactMap { detailsMap[$0] }
    }
    
    /// Calculates rolling upload speed (bytes/sec) for a series of progress samples.
    ///
    /// This implementation computes a **per-pair average** of upload speeds between consecutive
    /// samples, which smooths out spikes and gaps common in chunked uploads. Invalid pairs
    /// where the timestamp did not advance (`deltaTime <= 0`) are automatically skipped.
    ///
    /// The function assumes:
    /// - Each sample represents a cumulative `bytesSent` value (not per-interval bytes).
    /// - Samples are time-ordered (oldest first).
    /// - Only samples within the desired rolling window (e.g., last 5 seconds) are passed.
    ///
    /// - Parameter speedSamples: Ordered list of cumulative progress samples
    /// - Returns: Smoothed upload speed in bytes per second, or `0` if there are fewer than
    ///            two valid samples.
    private func calculateBytesPerSecond(for speedSamples: [CameraUploadTaskProgressRawDataEntity.SpeedSample]) -> Double {
        guard speedSamples.count >= 2 else { return 0 }
        
        var totalSpeed: Double = 0
        var validPairs = 0
        
        for (prev, next) in zip(speedSamples, speedSamples.dropFirst()) {
            let deltaTime = next.timestamp.timeIntervalSince(prev.timestamp)
            guard deltaTime > 0 else { continue }
            
            totalSpeed += Double(next.bytesSent - prev.bytesSent) / deltaTime
            validPairs += 1
        }
        
        guard validPairs > 0 else { return 0 }
        return totalSpeed / Double(validPairs)
    }
}
