import AsyncAlgorithms
import Foundation
import MEGAPreference
import MEGASwift

public enum CameraUploadPausedReason: Sendable {
    case notPaused
    case noWifi
    case noNetworkConnectivity
}

/// UseCase that provides information relating to the current active status of the CameraUploads in the application.
public protocol MonitorCameraUploadUseCaseProtocol: Sendable {
    var cameraUploadState: AnyAsyncSequence<CameraUploadStateEntity> { get }
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
    
    @PreferenceWrapper(key: PreferenceKeyEntity.cameraUploadsCellularDataUsageAllowed, defaultValue: false)
    private var cameraUploadsUseCellularDataUsageAllowed: Bool
    
    public var cameraUploadState: AnyAsyncSequence<CameraUploadStateEntity> {
        combineLatest(
            uploadStats(),
            pausedUploadState())
        .map { uploadStats, pausedReason -> CameraUploadStateEntity in
            if let pausedReason {
                pausedReason
            } else {
                uploadStats
            }
        }
        .removeDuplicates()
        .eraseToAnyAsyncSequence()
    }
    
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
    
    private func uploadStats() -> AnyAsyncSequence<CameraUploadStateEntity> {
        cameraUploadRepository.monitorChangedUploadStats()
            .map {
                .uploadStats($0)
            }
            .eraseToAnyAsyncSequence()
    }
        
    private func pausedUploadState() -> AnyAsyncSequence<CameraUploadStateEntity?> {
        combineLatest(
            networkPausedReason(),
            mediaTypePausedReason())
        .map { networkIssue, mediaTypePausedReason -> CameraUploadStateEntity? in
            if let networkIssue = networkIssue {
                .paused(reason: .networkIssue(networkIssue))
            } else if let mediaTypePausedReason {
                .paused(reason: mediaTypePausedReason)
            } else {
                nil
            }
        }
        .eraseToAnyAsyncSequence()
    }
    
    private func networkPausedReason() -> AnyAsyncSequence<CameraUploadStateEntity.PausedReason.NetworkIssue?> {
        networkMonitorUseCase.connectionSequence
            .prepend(networkMonitorUseCase.isConnected())
            .map { isConnectionSatisfied -> CameraUploadStateEntity.PausedReason.NetworkIssue? in
                if !isConnectionSatisfied {
                    .noConnection
                } else if !networkMonitorUseCase.isConnectedViaWiFi(), !cameraUploadsUseCellularDataUsageAllowed {
                    .noWifi
                } else {
                    nil
                }
            }
            .eraseToAnyAsyncSequence()
    }
    
    private func mediaTypePausedReason() -> AnyAsyncSequence<CameraUploadStateEntity.PausedReason?> {
        merge(
            cameraUploadRepository.photosUploadPausedReason,
            cameraUploadRepository.videosUploadPausedReason)
        .map { pausedReason -> CameraUploadStateEntity.PausedReason? in
            switch pausedReason {
            case .lowBattery: .lowBattery
            case .thermalState: .highThermalState
            case .none: nil
            }
        }
        .removeDuplicates()
        .eraseToAnyAsyncSequence()
    }
}
