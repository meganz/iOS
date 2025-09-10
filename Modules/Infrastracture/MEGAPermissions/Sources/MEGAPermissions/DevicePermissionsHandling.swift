import AVFoundation
import Photos
import UserNotifications

// This protocol abstracts the interface of requesting permissions and checking
// permission status for device permissions that application needs to offer all the
// features to the user
// Those permissions are:
//   1. access to microphone
//   2. access to camera
//   3. access to read write into photo album
//   4. permission to send and present remote push notifications to the user
//
// note:
// This pure Swift API, for classes using ObjC,
// there is a simplified wrapper: DevicePermissionHandlerObjCWrapper
// so please use it instead of exposing any of this to ObjC,
// but better still, convert code you touch to Swift
public protocol DevicePermissionsHandling: Sendable {
    
    // request read/write access level (do not use level directly, use .MEGAAccessLevel) to user's photo library
    // should return true if user given full or partial access
    // (.authorized or .limited)
    func requestPhotoLibraryAccessPermissions() async -> Bool

    // request add only access level to user's photo library
    // should return true if user given full or partial access
    // (.authorized or .limited)
    func requestPhotoLibraryAddOnlyPermissions() async -> Bool

    // request access to capture media, we are only using .video and .audio
    // uses AVCaptureDevice
    func requestPermission(for mediaType: AVMediaType) async -> Bool
    
    // Request from UNUserNotificationCenter permission to send badge and sound notifications
    func requestNotificationsPermission() async -> Bool
    
    // checks current status of authorization to user's photo library
    var photoLibraryAuthorizationStatus: PHAuthorizationStatus { get }
    
    // checks current authorization to microphone
    var audioPermissionAuthorizationStatus: AVAuthorizationStatus { get }
    
    // checks if access to camera is .authorized
    var isVideoPermissionAuthorized: Bool { get }
    
    // checks current status of permission to send push notifications to user
    // with badge and sound
    func notificationPermissionStatus() async -> UNAuthorizationStatus
    
    // returns true if microphone permission status is not determined (app needs/can to ask for permission)
    // false in any other case
    var shouldAskForAudioPermissions: Bool { get }
    
    // returns true if video permission status is not determined (app needs/can to ask for permission)
    // false in any other case
    var shouldAskForVideoPermissions: Bool { get }
    
    // returns true if photo library permission status is not determined (app needs/can to ask for permission)
    // false in any other case
    var shouldAskForPhotosPermissions: Bool { get }
    
    // returns true if permission status to push notifications is not determined
    // returns false for any other case
    func shouldAskForNotificationPermission() async -> Bool
    
    // returns true if photo library access is fully authorized (read write)
    var hasAuthorizedAccessToPhotoAlbum: Bool { get }
}

// Extension below contains closure - based of async API's defined in the core protocol
public extension DevicePermissionsHandling {
    
    private func request(
        asker: @MainActor @escaping () async -> Bool,
        handler: @MainActor  @escaping (Bool) -> Void
    ) {
        Task { @MainActor in 
            let granted = await asker()
            handler(granted)
        }
    }
    
    func requestAudioPermission(handler: @MainActor  @escaping (Bool) -> Void = { _ in }) {
        requestMediaPermission(mediaType: .audio, handler: handler)
    }
    
    func requestVideoPermission(handler: @MainActor  @escaping (Bool) -> Void = { _ in }) {
        requestMediaPermission(mediaType: .video, handler: handler)
    }
    
    private func requestMediaPermission(mediaType: AVMediaType, handler: @MainActor @escaping (Bool) -> Void) {
        request(asker: { await requestPermission(for: mediaType) }, handler: handler)
    }
    
    func photosPermissionWithCompletionHandler(handler: @MainActor @escaping (Bool) -> Void) {
        request(asker: { await requestPhotoLibraryAccessPermissions() }, handler: handler)
    }
    
    func notificationsPermission(with handler: @MainActor @escaping (Bool) -> Void) {
        request(asker: { await requestNotificationsPermission() }, handler: handler)
    }
    
    func shouldAskForNotificationsPermissions(handler: @MainActor @escaping (Bool) -> Void) {
        request(asker: { await shouldAskForNotificationPermission() }, handler: handler)
    }
        
    func notificationsPermissionsStatusDenied(handler: @MainActor @escaping (Bool) -> Void) {
        request(asker: { await notificationPermissionStatus() == .denied }, handler: handler)
    }
}

public extension DevicePermissionsHandling {
    // aggregate method that checks if any permission needs to be requested
    func shouldSetupPermissions() async -> Bool {
        
        let shouldAskForAudioPermissions = shouldAskForAudioPermissions
        let shouldAskForVideoPermissions = shouldAskForVideoPermissions
        let shouldAskForPhotosPermissions = shouldAskForPhotosPermissions
        
        return (
            await shouldAskForNotificationPermission() ||
            shouldAskForAudioPermissions ||
            shouldAskForVideoPermissions ||
            shouldAskForPhotosPermissions
        )
    }
    
    var isAudioPermissionAuthorized: Bool {
        switch audioPermissionAuthorizationStatus {
        case .notDetermined:
            return false
        case .restricted, .denied:
            return false
        default:
            return true
        }
    }
    
    var isPhotoLibraryAccessProhibited: Bool {
        let status = photoLibraryAuthorizationStatus
        return status == .restricted || status == .denied
    }
}
