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
    
    public func currentUploadStatus() async throws -> CameraUploadStatsEntity {
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
            .compactMap { [weak self] _ in try? await self?.currentUploadStatus() }
            .eraseToAnyAsyncSequence()
    }
}
