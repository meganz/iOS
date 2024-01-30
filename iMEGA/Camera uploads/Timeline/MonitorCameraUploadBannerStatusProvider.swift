import MEGADomain
import MEGAPermissions
import MEGASwift

struct MonitorCameraUploadBannerStatusProvider {
    
    private let monitorCameraUploadUseCase: any MonitorCameraUploadUseCaseProtocol
    private let devicePermissionHandler: any DevicePermissionsHandling
    
    init(monitorCameraUploadUseCase: some MonitorCameraUploadUseCaseProtocol,
         devicePermissionHandler: some DevicePermissionsHandling) {
        self.monitorCameraUploadUseCase = monitorCameraUploadUseCase
        self.devicePermissionHandler = devicePermissionHandler
    }
            
    func monitorCameraUploadStatusSequence() -> AnyAsyncSequence<CameraUploadBannerStatusViewStates> {
        monitorCameraUploadUseCase
            .monitorUploadStats()
            .map(map(uploadStats:))
            .eraseToAnyAsyncSequence()
    }
    
    private func map(uploadStats: CameraUploadStatsEntity) -> CameraUploadBannerStatusViewStates {
        guard uploadStats.pendingFilesCount == 0 else {
            switch monitorCameraUploadUseCase.possibleCameraUploadPausedReason() {
            case .noNetworkConnectivity:
                return .uploadPaused(reason: .noInternetConnection(numberOfFilesPending: uploadStats.pendingFilesCount))
            case .noWifi:
                return .uploadPaused(reason: .noWifiConnection(numberOfFilesPending: uploadStats.pendingFilesCount))
            case .notPaused:
                return .uploadInProgress(numberOfFilesPending: uploadStats.pendingFilesCount)
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
