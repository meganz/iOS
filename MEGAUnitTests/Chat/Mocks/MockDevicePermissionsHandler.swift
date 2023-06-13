@testable import MEGA

class MockDevicePermissionHandler: DevicePermissionsHandling {
    
    func audioPermission(
        modal: Bool,
        incomingCall: Bool,
        completion: @escaping (Bool) -> Void
    ) {
        
    }
    
    func alertAudioPermission(incomingCall: Bool) {
        
    }
    
    func contactsPermissionWithCompletionHandler(handler: @escaping (Bool) -> Void) {
        
    }
    
    var contactsAuthorizationStatus: CNAuthorizationStatus = .authorized
    
    func alertVideoPermissionWith(handler: @escaping () -> Void) {
        
    }
    
    var shouldAskForNotificaitonPermissionsCallCounter = 0
    var shouldAskForNotificaitonPermissionsValueToReturn = false
    func shouldAskForNotificationsPermissions(handler: @escaping (Bool) -> Void) {
        shouldAskForNotificaitonPermissionsCallCounter += 1
        handler(shouldAskForNotificaitonPermissionsValueToReturn)
    }
    
    var presentModalNotificationsPermissionPromptCallCount = 0
    func presentModalNotificationsPermissionPrompt() {
        presentModalNotificationsPermissionPromptCallCount += 1
    }
}
