import MEGAPreference

public protocol QueuedCameraUploadsUseCaseProtocol: Sendable {
    /// Retrieves a list of queued camera uploads based on the provided parameters.
    ///
    /// - Parameters:
    ///   - cursor: A cursor indicating the starting point for pagination.
    ///     If `nil`, the retrieval starts from the beginning or end depending on `isForward`.
    ///   - isForward: A Boolean value that determines the direction of pagination.
    ///     If `true`, results are fetched in ascending order; otherwise, in descending order.
    ///   - limit: The maximum number of uploads to retrieve. If `nil`, all matching uploads may be returned.
    ///
    /// - Returns: An array of `CameraAssetUploadEntity` objects representing queued uploads.
    ///
    /// - Throws: An error if the fetch operation fails.
    func queuedCameraUploads(
        startingFrom cursor: QueuedCameraUploadCursorEntity?,
        isForward: Bool,
        limit: Int?) async throws -> [CameraAssetUploadEntity]
}

public struct QueuedCameraUploadsUseCase: QueuedCameraUploadsUseCaseProtocol {
    private let cameraUploadAssetRepository: any CameraUploadAssetRepositoryProtocol
    
    @PreferenceWrapper(key: PreferenceKeyEntity.isCameraUploadsEnabled, defaultValue: false)
    private var isCameraUploadsEnabled: Bool
    @PreferenceWrapper(key: PreferenceKeyEntity.isVideoUploadEnabled, defaultValue: false)
    private var isVideoUploadEnabled: Bool
    
    public init(
        cameraUploadAssetRepository: some CameraUploadAssetRepositoryProtocol,
        preferenceRepository: some PreferenceRepositoryProtocol
    ) {
        self.cameraUploadAssetRepository = cameraUploadAssetRepository
        $isCameraUploadsEnabled.useCase = PreferenceUseCase(repository: preferenceRepository)
        $isVideoUploadEnabled.useCase = PreferenceUseCase(repository: preferenceRepository)
    }
    
    public func queuedCameraUploads(
        startingFrom cursor: QueuedCameraUploadCursorEntity?,
        isForward: Bool,
        limit: Int?
    ) async throws -> [CameraAssetUploadEntity] {
        guard isCameraUploadsEnabled else { return [] }
        
        return try await cameraUploadAssetRepository
            .uploads(
                startingFrom: cursor,
                isForward: isForward,
                limit: limit,
                statuses: [.notStarted, .notReady, .processing, .queuedUp, .cancelled, .failed],
                mediaTypes: mediaTypesForCameraUploads())
    }
    
    private func mediaTypesForCameraUploads() -> [PhotoAssetMediaTypeEntity] {
        var mediaTypes = [PhotoAssetMediaTypeEntity.image]
        if isVideoUploadEnabled {
            mediaTypes.append(.video)
        }
        return mediaTypes
    }
}
