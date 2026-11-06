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
    
    nonisolated(unsafe) static var remoteFeatureFlagRepository: any RemoteFeatureFlagRepositoryProtocol = RemoteFeatureFlagRepository.newRepo

    static var remoteFeatureFlagUseCase: some RemoteFeatureFlagUseCaseProtocol {
        RemoteFeatureFlagUseCase(repository: remoteFeatureFlagRepository)
    }
    
    static let uploadOnlyNewPhotosFeatureFlagCacheKey = "UploadOnlyNewPhotosFeatureFlagCache"

    /// The SDK only loads remote flags during fetchnodes, so a scan at process launch (e.g. background refresh)
    /// reads the flag as off. Until then, fall back to the value cached once flags were last loaded; with no
    /// cached value assume ON, since the preference can only have been turned on while the flag was on.
    @objc class var isUploadOnlyNewPhotosFeatureEnabled: Bool {
        if remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosUploadOnlyNewPhotos) {
            return true
        }
        return UserDefaults.standard.object(forKey: uploadOnlyNewPhotosFeatureFlagCacheKey) as? Bool ?? true
    }

    /// Caches the current remote flag value. Call only once remote flags are loaded (nodes current).
    @objc class func cacheUploadOnlyNewPhotosFeatureFlag() {
        UserDefaults.standard.set(
            remoteFeatureFlagUseCase.isFeatureFlagEnabled(for: .iosUploadOnlyNewPhotos),
            forKey: uploadOnlyNewPhotosFeatureFlagCacheKey
        )
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
        CameraUploadTelemetry.shared.appWillTerminate()
        cancelAllPendingOperations()
    }
}

extension CameraUploadManager: @unchecked Sendable { }
