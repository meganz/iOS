import MEGADomain
import MEGAPermissions
import MEGASwift

struct MonitorCameraUploadStatusProvider {
    
    private let monitorCameraUploadUseCase: any MonitorCameraUploadUseCaseProtocol
    private let devicePermissionHandler: any DevicePermissionsHandling
    
    init(monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol,
         devicePermissionHandler: some DevicePermissionsHandling) {
        self.monitorCameraUploadUseCase = monitorCameraUploadUseCase
        self.devicePermissionHandler = devicePermissionHandler
    }
            
    func monitorCameraUploadBannerStatusSequence() -> AnyAsyncSequence<CameraUploadBannerStatusViewStates> {
        monitorCameraUploadUseCase
            .monitorUploadStats()
            .map(mapBannerStatus(uploadStats:))
            .eraseToAnyAsyncSequence()
    }
    
    func monitorCameraUploadImageStatusSequence() -> AnyAsyncSequence<CameraUploadStatus> {
        monitorCameraUploadUseCase
            .monitorUploadStats()
            .map(mapImageStatus(uploadStats:))
            .eraseToAnyAsyncSequence()
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
        
        guard devicePermissionHandler.photoLibraryAuthorizationStatus != .limited else {
            return .uploadPartialCompleted(reason: .photoLibraryLimitedAccess)
        }
        
        guard uploadStats.pendingVideosCount > 0 else {
            return .uploadCompleted
        }

        return .uploadPartialCompleted(
            reason: .videoUploadIsNotEnabled(pendingVideoUploadCount: uploadStats.pendingVideosCount))
    }
}
