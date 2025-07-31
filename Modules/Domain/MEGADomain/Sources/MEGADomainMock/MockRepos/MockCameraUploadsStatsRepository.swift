import MEGADomain
import MEGASwift

public struct MockCameraUploadsStatsRepository: CameraUploadsStatsRepositoryProtocol {
    
    public static var newRepo: MockCameraUploadsStatsRepository { .init() }
    
    public let photosUploadPausedReason: AnyAsyncSequence<CameraUploadMediaTypePausedReasonEntity>
    public let videosUploadPausedReason: AnyAsyncSequence<CameraUploadMediaTypePausedReasonEntity>
    private let currentStats: CameraUploadStatsEntity
        
    public init(
        currentStats: CameraUploadStatsEntity = .init(progress: 1, pendingFilesCount: 0, pendingVideosCount: 0),
        photosUploadPausedReason: AnyAsyncSequence<CameraUploadMediaTypePausedReasonEntity> = SingleItemAsyncSequence(item: .none).eraseToAnyAsyncSequence(),
        videosUploadPausedReason: AnyAsyncSequence<CameraUploadMediaTypePausedReasonEntity> = SingleItemAsyncSequence(item: .none).eraseToAnyAsyncSequence()
    ) {
        self.currentStats = currentStats
        self.photosUploadPausedReason = photosUploadPausedReason
        self.videosUploadPausedReason = videosUploadPausedReason
    }
    
    public func currentUploadStats() async throws -> CameraUploadStatsEntity {
        currentStats
    }
    
    public func monitorChangedUploadStats() -> AnyAsyncSequence<CameraUploadStatsEntity> {
        SingleItemAsyncSequence(item: currentStats)
            .eraseToAnyAsyncSequence()
    }
}
