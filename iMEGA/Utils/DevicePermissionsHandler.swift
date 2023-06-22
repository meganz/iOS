import AVKit
import Contacts
import Photos
import UIKit

@objc
final class DevicePermissionsHandler: NSObject, DevicePermissionsHandling {
    override init() {
        super.init()
    }
    
    // MARK: - Permissions requests
    @objc
    func audioPermission(modal: Bool, incomingCall: Bool, completion: @escaping (Bool) -> Void) {
        
        if modal && shouldAskForAudioPermissions {
            modalAudioPermissionForIncomingCall(incomingCall: incomingCall, completion: completion)
            
        } else {
            audioPermissionWithCompletionHandler(handler: completion)
        }
    }
    
    func audioPermissionWithCompletionHandler(handler: @escaping (Bool) -> Void) {
        askAVPermission(permission: .audio, handler: handler)
    }
    
    @objc
    func videoPermissionWithCompletionHandler(handler: @escaping (Bool) -> Void) {
        askAVPermission(permission: .video, handler: handler)
    }
    
    private func askAVPermission(permission: AVMediaType, handler: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: permission) { permissionGranted in
            DispatchQueue.main.async {
                handler(permissionGranted)
            }
        }
    }
    
    @objc
    func photosPermissionWithCompletionHandler(handler: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                handler(status == .authorized || status == .limited)
            }
        }
    }
    
    @objc
    func contactsPermissionWithCompletionHandler(handler: @escaping (Bool) -> Void) {
        let contactStore = CNContactStore()
        contactStore.requestAccess(for: .contacts) { granted, _ in
            DispatchQueue.main.async {
                handler(granted)
            }
        }
    }
    
    // MARK: - Alerts
    @objc
    func alertAudioPermission(incomingCall: Bool) {
        if incomingCall {
            alertPermissionWith(
                title: NSLocalizedString("Incoming call", comment: ""),
                message: NSLocalizedString("microphonePermissions", comment: "Alert message to remember that MEGA app needs permission to use the Microphone to make calls and record videos and it doesn't have it"),
                completion: {}
            )
        } else {
            alertPermissionWith(
                message: NSLocalizedString("microphonePermissions", comment: "Alert message to remember that MEGA app needs permission to use the Microphone to make calls and record videos and it doesn't have it"),
                completion: {}
            )
        }
    }
    
    func alertVideoPermissionWith(handler: @escaping () -> Void) {
        alertPermissionWith(
            message: NSLocalizedString("cameraPermissions", comment: "Alert message to remember that MEGA app needs permission to use the Camera to take a photo or video and it doesn't have it"),
            completion: handler
        )
    }
    
    @objc
    func alertPhotosPermission() {
        alertPermissionWith(
            message: NSLocalizedString("photoLibraryPermissions", comment: "Alert message to explain that the MEGA app needs permission to access your device photos"),
            completion: {}
        )
    }
    
    func alertPermissionWith(message: String, completion: @escaping () -> Void) {
        alertPermissionWith(
            title: NSLocalizedString("attention", comment: "Alert title to attract attention"),
            message: message,
            completion: completion
        )
        
    }
    
    func alertPermissionWith(title: String, message: String, completion: @escaping () -> Void) {
    
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertController.addAction(.init(title: NSLocalizedString("notNow", comment: ""), style: .cancel, handler: nil))
        alertController.addAction(.init(title: NSLocalizedString("settingsTitle", comment: "Title of the Settings section"), style: .default, handler: { _ in
            completion()
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        }))
    
        UIApplication.mnz_presentingViewController().present(alertController, animated: true, completion: nil)
    
    }
    
    // MARK: - Modals
    
    func modalAudioPermissionForIncomingCall(incomingCall: Bool, completion: @escaping (Bool) -> Void) {
        let permissionsModal = CustomModalAlertViewController()
        
        permissionsModal.image = UIImage(named: "groupChat")
        permissionsModal.viewTitle = incomingCall ? NSLocalizedString("Incoming call", comment: "") : NSLocalizedString("Enable Microphone and Camera", comment: "Title label that explains that the user is going to be asked for the microphone and camera permission")
        permissionsModal.detail = NSLocalizedString("To make encrypted voice and video calls, allow MEGA access to your Camera and Microphone", comment: "Detailed explanation of why the user should give permission to access to the camera and the microphone")
        permissionsModal.firstButtonTitle = NSLocalizedString("Allow Access", comment: "Button which triggers a request for a specific permission, that have been explained to the user beforehand")
        permissionsModal.dismissButtonTitle = NSLocalizedString("notNow", comment: "")
        
        permissionsModal.firstCompletion = { [weak permissionsModal] in
            permissionsModal?.dismiss(animated: true, completion: {
                self.audioPermissionWithCompletionHandler(handler: completion)
            })
        }
        
        UIApplication.mnz_presentingViewController().present(permissionsModal, animated: true, completion: nil)
    }
    
    func presentModalNotificationsPermissionPrompt() {
    
        let permissionsModal = CustomModalAlertViewController()
    
        permissionsModal.image = UIImage(named: "micAndCamPermission")
        permissionsModal.viewTitle = NSLocalizedString("Enable Notifications", comment: "Title label that explains that the user is going to be asked for the notifications permission")
        permissionsModal.detail = NSLocalizedString("We would like to send you notifications so you receive new messages on your device instantly.", comment: "Detailed explanation of why the user should give permission to deliver notifications")
        permissionsModal.firstButtonTitle = NSLocalizedString("continue", comment: "'Next' button in a dialog")
    
        permissionsModal.firstCompletion = {[weak self, weak permissionsModal] in
            self?.notificationsPermission(with: { granted in
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                permissionsModal?.dismiss(animated: true)
            })
        }
    
        UIApplication.mnz_presentingViewController().present(permissionsModal, animated: true, completion: nil)
    
    }
    
    // MARK: - Permissions status
    
    @objc
    var shouldAskForAudioPermissions: Bool {
        avDeviceAuthorizationStatus(for: .audio) == .notDetermined
    }
    
    @objc
    var shouldAskForVideoPermissions: Bool {
        avDeviceAuthorizationStatus(for: .video) == .notDetermined
    }
    
    private var photoLibraryAuthorization: PHAuthorizationStatus {
        PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    var hasAuthorizedAccessToPhotoAlbum: Bool {
        photoLibraryAuthorization == .authorized
    }
    
    @objc
    var shouldAskForPhotosPermissions: Bool {
        photoLibraryAuthorization == .notDetermined
    }
    
    @objc
    func notificationsPermission(with handler: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                handler(granted)
            }
        }
    }
    //
    // this returns true in the completion only if authorization is not determined, so it will
    // return false if it's UNAuthorizationStatusDenied
    func shouldAskForNotificationsPermissions(handler: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                handler(settings.authorizationStatus == .notDetermined)
            }
        }
    }
    
    var contactsAuthorizationStatus: CNAuthorizationStatus {
        CNContactStore.authorizationStatus(for: .contacts)
    }
    
    @objc
    var shouldAskForContactsPermissions: Bool {
        contactsAuthorizationStatus == .notDetermined
    }
    
    @objc
    func shouldSetupPermissions(completion: @escaping (Bool) -> Void) {
    
        let shouldAskForAudioPermissions = shouldAskForAudioPermissions
        let shouldAskForVideoPermissions = shouldAskForVideoPermissions
        let shouldAskForPhotosPermissions = shouldAskForPhotosPermissions
        let shouldAskForContactsPermissions = shouldAskForContactsPermissions
        
        let syncShouldAsk = shouldAskForAudioPermissions || shouldAskForVideoPermissions || shouldAskForPhotosPermissions || shouldAskForContactsPermissions
        
        shouldAskForNotificationsPermissions { shouldAskForNotificationsPermissions in
            let shouldAsk = syncShouldAsk || shouldAskForNotificationsPermissions
            completion(shouldAsk)
        }
    }
    
    private func avDeviceAuthorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: mediaType)
    }
    
    private func isPermissionAuthorizedOrNotDetermined(_ mediaType: AVMediaType) -> Bool {
        avDeviceAuthorizationStatus(for: mediaType) == .authorized ||
        avDeviceAuthorizationStatus(for: mediaType) == .notDetermined
    }
    
    var isAudioPermissionAuthorizedOrNotDetermined: Bool {
        isPermissionAuthorizedOrNotDetermined(.audio)
    }
    
    var audioPermissionAuthorizationStatus: AVAuthorizationStatus {
        avDeviceAuthorizationStatus(for: .audio)
    }
    
    var isVideoPermissionAuthorizedOrNotDetermined: Bool {
        isPermissionAuthorizedOrNotDetermined(.video)
    }
    
    var isVideoPermissionAuthorized: Bool {
        avDeviceAuthorizationStatus(for: .video) == .authorized
    }
}
