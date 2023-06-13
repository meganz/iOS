import Foundation

@objc
protocol DevicePermissionsHandling: AnyObject {
    
    func shouldAskForNotificationsPermissions(handler: @escaping (Bool) -> Void)
    
    func presentModalNotificationsPermissionPrompt()
    
    @objc
    func audioPermission(modal: Bool, incomingCall: Bool, completion: @escaping (Bool) -> Void)
    
    @objc
    func alertAudioPermission(incomingCall: Bool)
    
    func contactsPermissionWithCompletionHandler(handler: @escaping (Bool) -> Void)
    
    var contactsAuthorizationStatus: CNAuthorizationStatus { get }
    
    func alertVideoPermissionWith(handler: @escaping () -> Void)
}
