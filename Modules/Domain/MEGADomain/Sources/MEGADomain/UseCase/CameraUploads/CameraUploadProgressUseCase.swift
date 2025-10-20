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
    
    /// The list of files currently being uploaded.
    ///
    /// Each element is a `CameraUploadFileDetailsEntity` representing a photo or video in progress.
    func inProgressFiles() async throws -> [CameraUploadFileDetailsEntity]
    
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
    
    public func inProgressFiles() async throws -> [CameraUploadFileDetailsEntity] {
        let inProgressUploadIdentifiers = try await inProgressUploadIdentifiers()
        try Task.checkCancellation()
        let details = try await cameraUploadAssetRepository.fileDetails(forLocalIdentifiers: inProgressUploadIdentifiers)
        try Task.checkCancellation()
        let detailsMap = Dictionary(uniqueKeysWithValues: details.map { ($0.localIdentifier, $0) })
        return inProgressUploadIdentifiers.compactMap { detailsMap[$0] }
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
    
    private func inProgressUploadIdentifiers() async throws -> Set<CameraUploadLocalIdentifierEntity> {
        try await transferProgressRepository.activeUploads.async
            .compactMap {
                try Task.checkCancellation()
                let progressData = await transferProgressRepository.progressRawData(for: $0)
                return if progressData.totalBytesSent > 0 {
                    $0
                } else {
                    nil
                }
            }
            .reduce(into: Set<CameraUploadLocalIdentifierEntity>()) { result, identifier in
                result.insert(identifier)
            }
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
