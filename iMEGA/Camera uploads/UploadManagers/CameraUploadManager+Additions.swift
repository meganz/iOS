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

    @objc class var isUploadOnlyNewPhotosFeatureEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .uploadOnlyNewPhotos)
    }
    
    func photoQueuePausedReason() -> CameraUploadMediaTypePausedReason? {
        concurrentCountCalculator.photoQueuePausedReason()
    }
    
    func videoQueuePausedReason() -> CameraUploadMediaTypePausedReason? {
        concurrentCountCalculator.videoQueuePausedReason()
    }
    
    /// Safe entry point for callers that may run before the singleton has been touched
    /// (e.g. AppDelegate.applicationWillTerminate). Lazy-initialising the singleton at
    /// termination time would schedule a BGTaskScheduler submit and crash, so we gate on the init flag.
    @objc class func appWillTerminate() {
        guard CameraUploadManager.isSharedInitialized else { return }
        CameraUploadManager.shared().appWillTerminate()
    }

    @objc func appWillTerminate() {
        guard !isAppWillTerminateHandled else {
            return
        }
        isAppWillTerminateHandled = true
        MEGALogDebug("[Camera Upload] app will terminate")
        cancelAllPendingOperations()
    }
}

extension CameraUploadManager: @unchecked Sendable { }
