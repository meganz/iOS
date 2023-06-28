@testable import MEGA

final class MockPermissionAlertRouter: PermissionAlertRouting {
    func audioPermission(
        modal: Bool,
        incomingCall: Bool,
        completion: @escaping (Bool) -> Void
    ) {}
    
    func alertAudioPermission(incomingCall: Bool) {}
    
    func alertVideoPermission() {}
    
    func alertPhotosPermission() {}
    
    var presentModalNotificationsPermissionPromptCallCount = 0
    func presentModalNotificationsPermissionPrompt() {
        presentModalNotificationsPermissionPromptCallCount += 1
    }
    
    func requestPermissionsFor(
        videoCall: Bool,
        granted: @escaping () -> Void
    ) {}
}
