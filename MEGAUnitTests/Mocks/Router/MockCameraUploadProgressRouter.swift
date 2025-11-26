@testable import MEGA

final class MockCameraUploadProgressRouter: CameraUploadProgressRouting {
    private(set) var startCalledCount = 0
    private(set) var showUpgradeAccountCalledCount = 0
    private(set) var showCameraUploadSettingsCalledCount = 0
    
    nonisolated init() {}
    
    func start(onCameraUploadSettingsChanged: (() -> Void)?) {
        onCameraUploadSettingsChanged?()
        startCalledCount += 1
    }
    
    func showUpgradeAccount() {
        showUpgradeAccountCalledCount += 1
    }
    
    func showCameraUploadSettings() {
        showCameraUploadSettingsCalledCount += 1
    }
}
