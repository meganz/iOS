import AsyncAlgorithms
import MEGAAppPresentation
import MEGADomain
import MEGAPermissions
import MEGASwift

struct MonitorCameraUploadStatusProvider {
    
    private let monitorCameraUploadUseCase: any MonitorCameraUploadUseCaseProtocol
    private let devicePermissionHandler: any DevicePermissionsHandling
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    
    init(monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol,
         devicePermissionHandler: some DevicePermissionsHandling,
         featureFlagProvider: any FeatureFlagProviderProtocol = DIContainer.featureFlagProvider
    ) {
        self.monitorCameraUploadUseCase = monitorCameraUploadUseCase
        self.devicePermissionHandler = devicePermissionHandler
        self.featureFlagProvider = featureFlagProvider
    }
            
    func monitorCameraUploadBannerStatusSequence() -> AnyAsyncSequence<CameraUploadBannerStatusViewStates> {
        if featureFlagProvider.isFeatureFlagEnabled(for: .cameraUploadsRevamp) {
            cameraUploadBannerStatus()
        } else {
            monitorCameraUploadUseCase
                .monitorUploadStats()
                .map(mapBannerStatus(uploadStats:))
                .eraseToAnyAsyncSequence()
        }
    }
    
    func monitorCameraUploadImageStatusSequence() -> AnyAsyncSequence<CameraUploadStatus> {
        if featureFlagProvider.isFeatureFlagEnabled(for: .cameraUploadsRevamp) {
            imageStatusSequence()
        } else {
            monitorCameraUploadUseCase
                .monitorUploadStats()
                .map(mapImageStatus(uploadStats:))
                .eraseToAnyAsyncSequence()
        }
    }
    
    func hasLimitedLibraryAccess() -> Bool {
        devicePermissionHandler.photoLibraryAuthorizationStatus == .limited
    }
    
    private func mapImageStatus(uploadStats: CameraUploadStatsEntity) -> CameraUploadStatus {
        guard uploadStats.pendingFilesCount == 0 else {
            switch monitorCameraUploadUseCase.possibleCameraUploadPausedReason() {
            case .notPaused:
                return .uploading(progress: uploadStats.progress)
            case .noWifi, .noNetworkConnectivity:
                return .warning
            }
        }
        return .completed
    }
    
    private func mapBannerStatus(uploadStats: CameraUploadStatsEntity) -> CameraUploadBannerStatusViewStates {
        guard uploadStats.pendingFilesCount == 0 else {
            return switch monitorCameraUploadUseCase.possibleCameraUploadPausedReason() {
            case .noNetworkConnectivity:
                    .uploadPaused(reason: .noInternetConnection)
            case .noWifi:
                    .uploadPaused(reason: .noWifiConnection)
            case .notPaused:
                    .uploadInProgress(numberOfFilesPending: uploadStats.pendingFilesCount)
            }
        }
        
       return cameraUploadBannerStatus(uploadStats: uploadStats)
    }
    
    private func cameraUploadBannerStatus() -> AnyAsyncSequence<CameraUploadBannerStatusViewStates> {
        monitorCameraUploadUseCase.cameraUploadState
            .map {
                switch $0 {
                case .uploadStats(let stats):
                    cameraUploadBannerStatus(uploadStats: stats)
                case .paused(reason: let reason):
                    .uploadPaused(reason: reason.toCameraUploadBannerStatusUploadPausedReason())
                }
            }
            .eraseToAnyAsyncSequence()
    }
    
    private func cameraUploadBannerStatus(uploadStats: CameraUploadStatsEntity) -> CameraUploadBannerStatusViewStates {
        guard uploadStats.pendingFilesCount == 0 else {
            return .uploadInProgress(numberOfFilesPending: uploadStats.pendingFilesCount)
        }
        
        guard devicePermissionHandler.photoLibraryAuthorizationStatus != .limited else {
            return .uploadPartialCompleted(reason: .photoLibraryLimitedAccess)
        }
        
        guard uploadStats.pendingVideosCount > 0 else {
            return .uploadCompleted
        }
        
        return .uploadPartialCompleted(
            reason: .videoUploadIsNotEnabled(pendingVideoUploadCount: uploadStats.pendingVideosCount))
    }
    
    private func imageStatusSequence() -> AnyAsyncSequence<CameraUploadStatus> {
        monitorCameraUploadUseCase.cameraUploadState
            .map {
                switch $0 {
                case .uploadStats(let stats):
                    imageStatus(uploadStats: stats)
                case .paused:
                    .warning
                }
            }
            .eraseToAnyAsyncSequence()
    }
    
    private func imageStatus(uploadStats: CameraUploadStatsEntity) -> CameraUploadStatus {
        guard uploadStats.pendingFilesCount == 0 else {
            return .uploading(progress: uploadStats.progress)
        }
        return .completed
    }
}

extension CameraUploadStateEntity.PausedReason {
    func toCameraUploadBannerStatusUploadPausedReason() -> CameraUploadBannerStatusUploadPausedReason {
        switch self {
        case .lowBattery: .lowBattery
        case .highThermalState: .highThermalState
        case .networkIssue(let issue):
            switch issue {
            case .noConnection: .noInternetConnection
            case .noWifi: .noWifiConnection
            }
        }
    }
}
