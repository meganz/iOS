import MEGADomain
import MEGASwift

public struct MockCameraUploadsStatsRepository: CameraUploadsStatsRepositoryProtocol {
    
    public static var newRepo: MockCameraUploadsStatsRepository { .init() }
    
    private let currentStats: CameraUploadStatsEntity
    
    public init(currentStats: CameraUploadStatsEntity = .init(progress: 1, pendingFilesCount: 0, pendingVideosCount: 0)) {
        self.currentStats = currentStats
    }
    
    public func currentUploadStats() async throws -> CameraUploadStatsEntity {
        currentStats
    }
    
    public func monitorChangedUploadStats() -> AnyAsyncSequence<CameraUploadStatsEntity> {
        SingleItemAsyncSequence(item: currentStats)
            .eraseToAnyAsyncSequence()
    }
}
