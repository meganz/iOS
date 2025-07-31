import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAPermissions

extension CameraUploadManager {
    @objc func scheduleCameraUploadBackgroundRefresh() {
        CameraUploadBGRefreshManager.shared.schedule()
    }
    
    @objc func cancelCameraUploadBackgroundRefresh() {
        CameraUploadBGRefreshManager.shared.cancel()
    }
    
    private class var permissionHandler: any DevicePermissionsHandling {
        DevicePermissionsHandler.makeHandler()
    }
    
    @objc
    class func disableCameraUploadIfAccessProhibited() {
        if
            permissionHandler.isPhotoLibraryAccessProhibited,
            Self.isCameraUploadEnabled {
            Self.shared().disableCameraUpload()
        }
    }
    
    @objc
    func initializeCameraUploadHeartbeat() {
        self.heartbeat = CameraUploadHeartbeat(
            cameraUploadsUseCase: CameraUploadsUseCase(cameraUploadsRepository: CameraUploadsRepository.newRepo),
            deviceUseCase: DeviceUseCase(repository: DeviceRepository.newRepo)
        )
    }
    
    @objc func trackCameraUploadsEnableStatus(_ enable: Bool) {
        DIContainer.tracker.trackAnalyticsEvent(with: enable ? DIContainer.cameraUploadsEnabled : DIContainer.cameraUploadsDisabled)
    }
    
    func photoQueuePausedReason() -> CameraUploadMediaTypePausedReason? {
        concurrentCountCalculator.photoQueuePausedReason()
    }
    
    func videoQueuePausedReason() -> CameraUploadMediaTypePausedReason? {
        concurrentCountCalculator.videoQueuePausedReason()
    }
}

extension CameraUploadManager: @unchecked Sendable { }
