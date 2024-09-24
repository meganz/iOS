import Foundation
import MEGASwift

public enum CameraUploadPausedReason {
    case notPaused
    case noWifi
    case noNetworkConnectivity
}

/// UseCase that provides information relating to the current active status of the CameraUploads in the application.
public protocol MonitorCameraUploadUseCaseProtocol: Sendable {
    
    ///  AsyncSequence that fires off CameraUploadStatsEntity relating to the status of active camera uploads occurring in the application.
    ///   A new stats update should be triggered when uploads have had a state change. This includes completions, failures or paused
    /// - Returns: AsyncSequence that emits CameraUploadStatsEntity, this sequence will continue to remain active and cancel only from cooperative cancellation. Use this sequence appropriately.
    func monitorUploadStats() -> AnyAsyncSequence<CameraUploadStatsEntity>
    
    /// Provides a determination for the possible reason that the current CameraUpload operation may have paused for.
    /// This is determined by the device active Camera Upload Settings and Active Network access.
    /// - Returns: CameraUploadPausedReason contain possible cases that is triggered a pause in uploads.
    func possibleCameraUploadPausedReason() -> CameraUploadPausedReason
}

public struct MonitorCameraUploadUseCase<S: CameraUploadsStatsRepositoryProtocol, T: NetworkMonitorUseCaseProtocol, U: PreferenceUseCaseProtocol>: MonitorCameraUploadUseCaseProtocol {
    
    private let cameraUploadRepository: S
    private let networkMonitorUseCase: T
    
    @PreferenceWrapper(key: .cameraUploadsCellularDataUsageAllowed, defaultValue: false)
    private var cameraUploadsUseCellularDataUsageAllowed: Bool
    
    public init(cameraUploadRepository: S, networkMonitorUseCase: T, preferenceUseCase: U) {
        self.cameraUploadRepository = cameraUploadRepository
        self.networkMonitorUseCase = networkMonitorUseCase
        $cameraUploadsUseCellularDataUsageAllowed.useCase = preferenceUseCase
    }
    
    public func monitorUploadStats() -> AnyAsyncSequence<CameraUploadStatsEntity> {
        AsyncStream<CameraUploadStatsEntity> { continuation in
            let monitorUploadStatsTask = Task {
                for await stats in cameraUploadRepository.monitorChangedUploadStats() {
                    continuation.yield(stats)
                }
            }
            
            let monitorNetworkTask = Task {
                for await stats in networkMonitorUseCase
                    .connectionSequence
                    .compactMap({ _ in try? await cameraUploadRepository.currentUploadStats() }) {
                    continuation.yield(stats)
                }
            }
            
            continuation.onTermination = { @Sendable _ in
                [monitorUploadStatsTask, monitorNetworkTask]
                    .forEach { $0.cancel() }
            }
        }.eraseToAnyAsyncSequence()
    }
    
    public func possibleCameraUploadPausedReason() -> CameraUploadPausedReason {
        if !networkMonitorUseCase.isConnectedViaWiFi(), !cameraUploadsUseCellularDataUsageAllowed {
            return .noWifi
        } else if cameraUploadsUseCellularDataUsageAllowed, !networkMonitorUseCase.isConnected() {
            return .noNetworkConnectivity
        } else {
            return .notPaused
        }
    }
}
