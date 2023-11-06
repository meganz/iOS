import MEGADomain
import MEGASwift

public struct MockMonitorCameraUploadUseCase: MonitorCameraUploadUseCaseProtocol {
    public let monitorUploadStatus: AnyAsyncSequence<CameraUploadStatsEntity>
    
    public init(
        monitorUploadStatus: AnyAsyncSequence<CameraUploadStatsEntity> = EmptyAsyncSequence<CameraUploadStatsEntity>().eraseToAnyAsyncSequence()) {
        self.monitorUploadStatus = monitorUploadStatus
    }
}
