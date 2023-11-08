import MEGADomain
import MEGASwift

public struct MockMonitorCameraUploadUseCase: MonitorCameraUploadUseCaseProtocol {
    public let monitorUploadStatus: AnyAsyncSequence<Result<CameraUploadStatsEntity, Error>>
    
    public init(
        monitorUploadStatus: AnyAsyncSequence<Result<CameraUploadStatsEntity, Error>> = EmptyAsyncSequence<Result<CameraUploadStatsEntity, Error>>().eraseToAnyAsyncSequence()) {
        self.monitorUploadStatus = monitorUploadStatus
    }
}
