
extension CameraUploadManager {
    @objc func scheduleCameraUploadBackgroundRefresh() {
        CameraUploadBGRefreshManager.shared.schedule()
    }
    
    @objc func cancelCameraUploadBackgroundRefresh() {
        CameraUploadBGRefreshManager.shared.cancel()
    }
}
