@testable import MEGA

class MockDevicePermissionHandler: DevicePermissionsHandling {
    init() {
        
    }
    
    convenience init(
        photoAuthorization: PHAuthorizationStatus,
        audioAuthorized: Bool,
        videoAuthorized: Bool
    ) {
        self.init()
        photoLibraryAuthorizationStatus = photoAuthorization
        requestMediaPermissionValuesToReturn[.audio] = audioAuthorized
        requestMediaPermissionValuesToReturn[.video] = videoAuthorized
    }
    
    func notificationPermissionStatus() async -> UNAuthorizationStatus {
        .denied
    }
    
    func requestPhotoLibraryAccessPermissions() async -> Bool { false }
    
    var requestPermissionsMediaTypes: [AVMediaType] = []
    var requestMediaPermissionValuesToReturn: [AVMediaType: Bool] = [:]
    
    func requestPermission(for mediaType: AVMediaType) async -> Bool {
        requestPermissionsMediaTypes.append(mediaType)
        return requestMediaPermissionValuesToReturn[mediaType]!
    }
    
    func requestContactsPermissions() async -> Bool { false }
    
    func requestNotificationsPermission() async -> Bool { false }
    
    var shouldAskForAudioPermissions: Bool = false
    
    var shouldAskForVideoPermissions: Bool = false
    
    var shouldAskForPhotosPermissions: Bool = false
    
    var shouldAskForContactsPermissions: Bool = false
    
    var shouldAskForNotificaitonPermissionsValueToReturn = false
    func shouldAskForNotificationPermission() async -> Bool {
        shouldAskForNotificaitonPermissionsValueToReturn
    }
    
    var hasAuthorizedAccessToPhotoAlbum: Bool = false
    
    var contactsAuthorizationStatus: CNAuthorizationStatus = .notDetermined
    
    var photoLibraryAuthorizationStatus: PHAuthorizationStatus = .notDetermined
    
    var audioPermissionAuthorizationStatus: AVAuthorizationStatus = .notDetermined
    
    var isVideoPermissionAuthorized: Bool = false
}
