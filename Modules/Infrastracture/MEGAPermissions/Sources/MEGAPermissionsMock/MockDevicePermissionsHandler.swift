import AVFoundation
import MEGAPermissions
import Photos
import UserNotifications

public final class MockDevicePermissionHandler: DevicePermissionsHandling, @unchecked Sendable {
    
    private var requestPhotoLibraryAccessPermissionsGranted: Bool = false

    private var requestPhotoLibraryAddOnlyPermissionsGranted: Bool = false

    public init() { }
    
    public convenience init(
        photoAuthorization: PHAuthorizationStatus = .notDetermined,
        audioAuthorized: Bool = false,
        videoAuthorized: Bool = false,
        requestPhotoLibraryAccessPermissionsGranted: Bool = false,
        requestPhotoLibraryAddOnlyPermissionsGranted: Bool = false
    ) {
        self.init()
        photoLibraryAuthorizationStatus = photoAuthorization
        requestMediaPermissionValuesToReturn[.audio] = audioAuthorized
        requestMediaPermissionValuesToReturn[.video] = videoAuthorized
        self.requestPhotoLibraryAccessPermissionsGranted = requestPhotoLibraryAccessPermissionsGranted
        self.requestPhotoLibraryAddOnlyPermissionsGranted = requestPhotoLibraryAddOnlyPermissionsGranted
    }

    public var notificationPermissionStatusToReturn: UNAuthorizationStatus = .notDetermined
    public func notificationPermissionStatus() async -> UNAuthorizationStatus {
        notificationPermissionStatusToReturn
    }
    
    public func requestPhotoLibraryAccessPermissions() async -> Bool { requestPhotoLibraryAccessPermissionsGranted }

    public func requestPhotoLibraryAddOnlyPermissions() async -> Bool { requestPhotoLibraryAddOnlyPermissionsGranted }

    public var requestPermissionsMediaTypes: [AVMediaType] = []
    public var requestMediaPermissionValuesToReturn: [AVMediaType: Bool] = [:]
    
    public func requestPermission(for mediaType: AVMediaType) async -> Bool {
        requestPermissionsMediaTypes.append(mediaType)
        return requestMediaPermissionValuesToReturn[mediaType]!
    }

    public var requestNotificationsPermissionToReturn: Bool = false
    public func requestNotificationsPermission() async -> Bool {
        requestNotificationsPermissionToReturn
    }

    public var shouldAskForAudioPermissions: Bool = false
    
    public var shouldAskForVideoPermissions: Bool = false
    
    public var shouldAskForPhotosPermissions: Bool = false
    
    public var shouldAskForNotificationPermissionsValueToReturn = false
    
    public func shouldAskForNotificationPermission() async -> Bool {
        shouldAskForNotificationPermissionsValueToReturn
    }
    
    public var hasAuthorizedAccessToPhotoAlbum: Bool = false
    
    public var photoLibraryAuthorizationStatus: PHAuthorizationStatus = .notDetermined
    
    public var audioPermissionAuthorizationStatus: AVAuthorizationStatus = .notDetermined
    
    public var isVideoPermissionAuthorized: Bool = false
}
