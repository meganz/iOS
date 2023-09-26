@testable import MEGA

final class MockPermissionAlertRouter: PermissionAlertRouting {
    
    let isAudioPermissionGranted: Bool
    var presentModalNotificationsPermissionPromptCallCount = 0
    
    init(isAudioPermissionGranted: Bool = true) {
        self.isAudioPermissionGranted = isAudioPermissionGranted
    }
    
    func audioPermission(
        modal: Bool,
        incomingCall: Bool,
        completion: @escaping (Bool) -> Void
    ) {
        completion(isAudioPermissionGranted)
    }
    
    func alertAudioPermission(incomingCall: Bool) {}
    
    func alertVideoPermission() {}
    
    func alertPhotosPermission() {}
    
    func presentModalNotificationsPermissionPrompt() {
        presentModalNotificationsPermissionPromptCallCount += 1
    }
    
    func requestPermissionsFor(
        videoCall: Bool,
        granted: @escaping () -> Void
    ) {}
}
