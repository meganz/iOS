import MEGADomain
import MEGASwift

public struct MockMonitorCameraUploadUseCase: MonitorCameraUploadUseCaseProtocol {
    
    let _monitorUploadStats: AnyAsyncSequence<CameraUploadStatsEntity>
    let possiblePauseReason: CameraUploadPausedReason
    
    public init(monitorUploadStats: AnyAsyncSequence<CameraUploadStatsEntity> = EmptyAsyncSequence<CameraUploadStatsEntity>().eraseToAnyAsyncSequence(),
                possiblePauseReason: CameraUploadPausedReason = .notPaused) {
        self._monitorUploadStats = monitorUploadStats
        self.possiblePauseReason = possiblePauseReason
    }
    
    public func monitorUploadStats() -> AnyAsyncSequence<CameraUploadStatsEntity> {
        _monitorUploadStats
    }
    
    public func possibleCameraUploadPausedReason() -> CameraUploadPausedReason {
        possiblePauseReason
    }
}
