
extension CameraUploadManager {
    @objc func scheduleCameraUploadBackgroundRefresh() {
        CameraUploadBGRefreshManager.shared.schedule()
    }
    
    @objc func cancelCameraUploadBackgroundRefresh() {
        CameraUploadBGRefreshManager.shared.cancel()
    }
    
    private class var permissionHandler: DevicePermissionsHandling {
        DevicePermissionsHandler.makeHandler()
    }
    
    @objc
    class func disableCameraUploadIfAccessProhibited() {
        if
            permissionHandler.isPhotoLibraryAccessProhibited,
            Self.isCameraUploadEnabled
        {
            Self.shared().disableCameraUpload()
        }
    }
}
