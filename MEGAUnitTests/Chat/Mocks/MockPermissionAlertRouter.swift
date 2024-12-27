@testable import MEGA

@MainActor
final class MockPermissionAlertRouter: PermissionAlertRouting {
    
    let isAudioPermissionGranted: Bool
    let isVideoPermissionGranted: Bool
    var presentModalNotificationsPermissionPromptCallCount = 0
    
    init(isAudioPermissionGranted: Bool = true,
         isVideoPermissionGranted: Bool = true) {
        self.isAudioPermissionGranted = isAudioPermissionGranted
        self.isVideoPermissionGranted = isVideoPermissionGranted
    }
    
    func audioPermission(
        modal: Bool,
        incomingCall: Bool,
        completion: @escaping @MainActor @Sendable (Bool) -> Void
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
        granted: @escaping @MainActor () -> Void
    ) {
        guard isAudioPermissionGranted else { return }
        if videoCall {
            guard isVideoPermissionGranted else { return }
            granted()
        } else {
            granted()
        }
    }
}
