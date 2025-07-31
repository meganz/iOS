import MEGADomain
import MEGASwift
import Photos

public final class CameraUploadsStatsRepository: CameraUploadsStatsRepositoryProtocol {
    
    public static var newRepo: CameraUploadsStatsRepository {
        .init(cameraUploadManager: .shared(),
              notificationCenter: .default)
    }
    
    private let cameraUploadManager: CameraUploadManager
    private let notificationCenter: NotificationCenter

    init(cameraUploadManager: CameraUploadManager,
         notificationCenter: NotificationCenter) {
        self.cameraUploadManager = cameraUploadManager
        self.notificationCenter = notificationCenter
    }
    
    public var photosUploadPausedReason: AnyAsyncSequence<CameraUploadMediaTypePausedReasonEntity> {
        notificationCenter
            .publisher(for: Notification.Name.MEGACameraUploadPhotoConcurrentCountChanged)
            .map { notification in
                (notification.userInfo?[MEGACameraUploadsPhotosPausedReasonUserInfoKey] as? CameraUploadMediaTypePausedReason)?
                    .toCameraUploadPausedReasonEntity() ?? .none
            }
            .values
            .prepend { [weak cameraUploadManager] in
                cameraUploadManager?.photoQueuePausedReason()?.toCameraUploadPausedReasonEntity() ?? .none
            }
            .eraseToAnyAsyncSequence()
    }
    
    public var videosUploadPausedReason: AnyAsyncSequence<CameraUploadMediaTypePausedReasonEntity> {
        notificationCenter
            .publisher(for: Notification.Name.MEGACameraUploadVideoConcurrentCountChanged)
            .map { notification in
                (notification.userInfo?[MEGACameraUploadsVideosPausedReasonUserInfoKey] as? CameraUploadMediaTypePausedReason)?
                    .toCameraUploadPausedReasonEntity() ?? .none
            }
            .values
            .prepend { [weak cameraUploadManager] in
                cameraUploadManager?.videoQueuePausedReason()?.toCameraUploadPausedReasonEntity() ?? .none
            }
            .eraseToAnyAsyncSequence()
    }
    
    public func currentUploadStats() async throws -> CameraUploadStatsEntity {
        let currentStats = try await cameraUploadManager.loadCurrentUploadStats()
        let videoUploadStats = try await cameraUploadManager.loadUploadStats(
            forMediaTypes: [PHAssetMediaType.video.rawValue as NSNumber])
        
        return CameraUploadStatsEntity(
            progress: currentStats.progress,
            pendingFilesCount: currentStats.pendingFilesCount,
            pendingVideosCount: videoUploadStats.pendingFilesCount)
    }
    
    public func monitorChangedUploadStats() -> AnyAsyncSequence<CameraUploadStatsEntity> {
        notificationCenter
            .publisher(for: Notification.Name.MEGACameraUploadStatsChanged)
            .map { _ in () }
            .prepend(())
            .values
            .compactMap { [weak self] _ in try? await self?.currentUploadStats() }
            .eraseToAnyAsyncSequence()
    }
}
