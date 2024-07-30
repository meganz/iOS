// This is a wrapper to get authorizations status, ask for it and show alerts inform about denial
// Use this class only from legacy ObjC, for
// Swift code use DevicePermissionsHandling protocol and PermissionAlertRouter instead
// Using this wrapper class instead of making DevicePermissionsHandling protocol visible
// to ObjC, to make it's Swift implementation pure without any knowlege
// of objC, to make it safe and easy to remove interface ObjC->Swift once ech file and class
// is converted to Swift.
import MEGAPermissions

class DevicePermissionsHandlerObjC: NSObject {
    
    private let permissionHandler: any DevicePermissionsHandling
    
    private var router: PermissionAlertRouter {
        PermissionAlertRouter.makeRouter(deviceHandler: permissionHandler)
    }
    
    override init() {
        permissionHandler = DevicePermissionsHandler.makeHandler()
        super.init()
    }
    
    @objc
    func shouldAskForNotificationsPermissions(with handler: @escaping (Bool) -> Void) {
        permissionHandler.shouldAskForNotificationsPermissions(handler: handler)
    }
    
    @objc
    func presentModalNotificationsPermissionPrompt() {
        router.presentModalNotificationsPermissionPrompt()
    }
    
    @objc
    func notificationsPermission(with handler: @escaping (Bool) -> Void) {
        permissionHandler.notificationsPermission(with: handler)
    }
    
    @objc
    func alertAudioPermission(incomingCall: Bool) {
        router.alertAudioPermission(incomingCall: incomingCall)
    }
    
    @objc
    func audioPermission(
        modal: Bool,
        incomingCall: Bool,
        completion: @escaping (Bool) -> Void
    ) {
        router.audioPermission(modal: modal, incomingCall: incomingCall) { granted in
            completion(granted)
        }
    }
    @objc
    func requstPhotoAlbumAccessPermissionsWithGrantedHandler(_ grantedHandler: @escaping () -> Void) {
        permissionHandler.photosPermissionWithCompletionHandler {[weak self] granted in
            if granted {
                grantedHandler()
            } else {
                self?.router.alertPhotosPermission()
            }
        }
    }
    
    @objc
    func alertPhotosPermission() {
        router.alertPhotosPermission()
    }
    
    @objc
    func requstPhotoAlbumAccessPermissionsWithHandler(_ handler: @escaping (Bool) -> Void) {
        permissionHandler.photosPermissionWithCompletionHandler(handler: handler)
    }
    
    @objc
    func requestVideoPermissionWithHandler(_ handler: @escaping (Bool) -> Void) {
        permissionHandler.requestVideoPermission(handler: handler)
    }
    @objc
    func requestAudioPermissionWithHandler(_ handler: @escaping (Bool) -> Void) {
        permissionHandler.requestAudioPermission(handler: handler)
    }
    
    @objc
    var shouldAskForPhotosPermissions: Bool {
        permissionHandler.shouldAskForPhotosPermissions
    }
    
    @objc
    var shouldAskForAudioPermissions: Bool {
        permissionHandler.shouldAskForAudioPermissions
    }
    
    @objc
    var shouldAskForVideoPermissions: Bool {
        permissionHandler.shouldAskForVideoPermissions
    }
    
    @objc
    func shouldAskForNotificationsPermissionsWithHandler(_ handler: @escaping (Bool) -> Void) {
        permissionHandler.shouldAskForNotificationsPermissions(handler: handler)
    }
    @objc
    func shouldSetupPermissionsWithCompletion(_ completion: @Sendable @escaping (Bool) -> Void) {
        Task { @MainActor in
            let shouldSetup = await permissionHandler.shouldSetupPermissions()
            await MainActor.run { completion(shouldSetup) }
        }
    }
    
    @objc
    func alertVideoPermission() {
        router.alertVideoPermission()
    }
}
