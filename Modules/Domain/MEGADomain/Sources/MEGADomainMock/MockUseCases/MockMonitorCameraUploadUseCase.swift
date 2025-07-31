import MEGADomain
import MEGASwift

public struct MockMonitorCameraUploadUseCase: MonitorCameraUploadUseCaseProtocol {
    public let cameraUploadState: AnyAsyncSequence<CameraUploadStateEntity>
    let _monitorUploadStats: AnyAsyncSequence<CameraUploadStatsEntity>
    let possiblePauseReason: CameraUploadPausedReason
    
    public init(
        monitorUploadStats: AnyAsyncSequence<CameraUploadStatsEntity> = EmptyAsyncSequence<CameraUploadStatsEntity>().eraseToAnyAsyncSequence(),
        possiblePauseReason: CameraUploadPausedReason = .notPaused,
        cameraUploadState: AnyAsyncSequence<CameraUploadStateEntity> = EmptyAsyncSequence<CameraUploadStateEntity>().eraseToAnyAsyncSequence()
    ) {
        self._monitorUploadStats = monitorUploadStats
        self.possiblePauseReason = possiblePauseReason
        self.cameraUploadState = cameraUploadState
    }
    
    public func monitorUploadStats() -> AnyAsyncSequence<CameraUploadStatsEntity> {
        _monitorUploadStats
    }
    
    public func possibleCameraUploadPausedReason() -> CameraUploadPausedReason {
        possiblePauseReason
    }
}
