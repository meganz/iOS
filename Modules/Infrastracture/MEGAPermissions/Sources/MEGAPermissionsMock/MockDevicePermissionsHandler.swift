import AVFoundation
import Contacts
import MEGAPermissions
import Photos
import UserNotifications

public class MockDevicePermissionHandler: DevicePermissionsHandling {
    public init() {
        
    }
    
    public convenience init(
        photoAuthorization: PHAuthorizationStatus,
        audioAuthorized: Bool,
        videoAuthorized: Bool
    ) {
        self.init()
        photoLibraryAuthorizationStatus = photoAuthorization
        requestMediaPermissionValuesToReturn[.audio] = audioAuthorized
        requestMediaPermissionValuesToReturn[.video] = videoAuthorized
    }
    
    public func notificationPermissionStatus() async -> UNAuthorizationStatus {
        .denied
    }
    
    public func requestPhotoLibraryAccessPermissions() async -> Bool { false }
    
    public var requestPermissionsMediaTypes: [AVMediaType] = []
    public var requestMediaPermissionValuesToReturn: [AVMediaType: Bool] = [:]
    
    public func requestPermission(for mediaType: AVMediaType) async -> Bool {
        requestPermissionsMediaTypes.append(mediaType)
        return requestMediaPermissionValuesToReturn[mediaType]!
    }
    
    public func requestContactsPermissions() async -> Bool { false }
    
    public func requestNotificationsPermission() async -> Bool { false }
    
    public var shouldAskForAudioPermissions: Bool = false
    
    public var shouldAskForVideoPermissions: Bool = false
    
    public var shouldAskForPhotosPermissions: Bool = false
    
    public var shouldAskForContactsPermissions: Bool = false
    
    public var shouldAskForNotificaitonPermissionsValueToReturn = false
    public func shouldAskForNotificationPermission() async -> Bool {
        shouldAskForNotificaitonPermissionsValueToReturn
    }
    
    public var hasAuthorizedAccessToPhotoAlbum: Bool = false
    
    public var contactsAuthorizationStatus: CNAuthorizationStatus = .notDetermined
    
    public var photoLibraryAuthorizationStatus: PHAuthorizationStatus = .notDetermined
    
    public var audioPermissionAuthorizationStatus: AVAuthorizationStatus = .notDetermined
    
    public var isVideoPermissionAuthorized: Bool = false
}
