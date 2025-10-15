import MEGASwift

public protocol CameraUploadTransferProgressRepositoryProtocol: Sendable {
    /// The list of currently active camera uploads.
    ///
    /// Each element in the array represents a `CameraUploadLocalIdentifierEntity`
    /// corresponding to a photo or video that is being uploaded.
    var activeUploads: [CameraUploadLocalIdentifierEntity] { get async }
    
    /// Provides an asynchronous sequence that emits updates to asset upload events.
    ///
    /// Each element in the sequence is a `CameraUploadAssetUploadEventEntity` representing
    /// a change in the state of a specific asset upload. For example, an event is emitted
    /// when a new upload starts, progresses, or completes.
    ///
    /// - Returns: An asynchronous sequence of asset upload events.
    var cameraUploadPhaseEventUpdates: AnyAsyncSequence<CameraUploadPhaseEventEntity> { get async }
    
    /// Registers a new camera upload transfer task with the repository.
    ///
    /// Call this method when a new upload task starts to begin tracking its progress.
    ///
    /// - Parameters:
    ///   - identifier: The unique identifier for the network task.
    ///   - info: Entity containing metadata about the upload task, including the local identifier.
    ///   - totalBytesExpectedToWrite: The total size of the file in bytes that will be uploaded.
    func registerTask(identifier: Int, info: CameraUploadTaskInfoEntity, totalBytesExpectedToWrite: Int64) async
    
    /// Updates the progress of an ongoing camera upload transfer task.
    ///
    /// Call this method periodically during an upload to update the current progress information.
    ///
    /// - Parameters:
    ///   - identifier: The unique identifier for the network task.
    ///   - info: Entity containing metadata about the upload task.
    ///   - totalBytesSent: The current number of bytes that have been sent for this task.
    ///   - totalBytesExpected: The total number of bytes expected to be sent for this task.
    func updateTaskProgress(identifier: Int, info: CameraUploadTaskInfoEntity, totalBytesSent: Int64, totalBytesExpected: Int64) async
    
    /// Marks a camera upload transfer task as completed.
    ///
    /// Call this method when an upload task finishes successfully.
    ///
    /// - Parameters:
    ///   - identifier: The unique identifier for the network task.
    ///   - info: Entity containing metadata about the upload task.
    func completeTask(identifier: Int, info: CameraUploadTaskInfoEntity) async
    
    /// Restores the state of an ongoing camera upload, typically after an app restart or when resuming interrupted uploads.
    ///
    /// Use this method to re-establish progress tracking for a previously started upload by mapping existing task identifiers
    /// and byte counts back to their corresponding chunks.
    ///
    /// - Parameters:
    ///   - localIdentifier: The local identifier of the asset being uploaded.
    ///   - taskIdentifierForChunk: A dictionary mapping each chunk index to its corresponding URLSession task identifier.
    ///   - totalBytesSent: The total number of bytes that have already been uploaded across all chunks for this asset.
    ///   - expectedBytesPerChunk: A dictionary mapping each chunk index to the total number of bytes expected for that chunk.
    func restoreTasks(
        for localIdentifier: CameraUploadLocalIdentifierEntity,
        taskIdentifierForChunk: [Int: Int],
        totalBytesSent: Int64,
        expectedBytesPerChunk: [Int: Int64]
    ) async
    
    /// Retrieves the raw progress data for a specific upload.
    ///
    /// Use this method to get the most recent progress values for an ongoing
    /// or completed upload, identified by its local identifier.
    ///
    /// - Parameter localIdentifier: The local identifier of the upload task.
    /// - Returns: A `CameraUploadTaskProgressRawDataEntity` containing the raw
    ///   progress details such as bytes sent and expected.
    func progressRawData(for localIdentifier: CameraUploadLocalIdentifierEntity) async -> CameraUploadTaskProgressRawDataEntity
    
    /// Creates and returns an async sequence that reports progress updates for a specific camera upload.
    ///
    /// Use this method to observe the progress of a particular file upload identified by its local identifier.
    ///
    /// - Parameter localIdentifier: The local identifier of the file being uploaded.
    /// - Returns: An asynchronous sequence that emits progress updates for the specified upload.
    func progressRawDataUpdates(for localIdentifier: CameraUploadLocalIdentifierEntity) async -> AnyAsyncSequence<CameraUploadTaskProgressRawDataEntity>
}
