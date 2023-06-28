import AVKit
import Contacts
import Photos
import UIKit

extension PHAccessLevel {
    // app requests read/write access
    static let MEGAAccessLevel: PHAccessLevel = .readWrite
}

struct DevicePermissionsHandler {
    
    init(
        mediaAccessor: @escaping (AVMediaType) async -> Bool,
        mediaStatusAccessor: @escaping (AVMediaType) -> AVAuthorizationStatus,
        photoAccessor: @escaping (PHAccessLevel) async -> PHAuthorizationStatus,
        photoStatusAccessor: @escaping (PHAccessLevel) -> PHAuthorizationStatus,
        contactsAccessor: @escaping () async -> Bool,
        contactStatusAccessor: @escaping () -> CNAuthorizationStatus,
        notificationsAccessor: @escaping () async -> Bool,
        notificationsStatusAccessor: @escaping () async -> UNAuthorizationStatus
    ) {
        self.mediaAccessor = mediaAccessor
        self.mediaStatusAccessor = mediaStatusAccessor
        self.photoAccessor = photoAccessor
        self.photoStatusAccessor = photoStatusAccessor
        self.contactsAccessor = contactsAccessor
        self.contactStatusAccessor = contactStatusAccessor
        self.notificationsAccessor = notificationsAccessor
        self.notificationsStatusAccessor = notificationsStatusAccessor
    }
    
    private let mediaAccessor: (AVMediaType) async -> Bool
    private let mediaStatusAccessor: (AVMediaType) -> AVAuthorizationStatus
    
    private let photoAccessor: (PHAccessLevel) async -> PHAuthorizationStatus
    private let photoStatusAccessor: (PHAccessLevel) -> PHAuthorizationStatus
    
    private let contactsAccessor: () async -> Bool
    private let contactStatusAccessor: () -> CNAuthorizationStatus
    
    private let notificationsAccessor: () async -> Bool
    private let notificationsStatusAccessor: () async -> UNAuthorizationStatus
    
}

extension DevicePermissionsHandler {
    static func makeHandler() -> Self {
        .init(
            mediaAccessor: { await AVCaptureDevice.requestAccess(for: $0) },
            mediaStatusAccessor: { AVCaptureDevice.authorizationStatus(for: $0) },
            photoAccessor: { await PHPhotoLibrary.requestAuthorization(for: $0) },
            photoStatusAccessor: { PHPhotoLibrary.authorizationStatus(for: $0) },
            contactsAccessor: {
                await withUnsafeContinuation { continuation in
                    let contactStore = CNContactStore()
                    contactStore.requestAccess(for: .contacts) { granted, _ in
                        continuation.resume(returning: granted)
                    }
                }
            },
            contactStatusAccessor: { CNContactStore.authorizationStatus(for: .contacts) },
            notificationsAccessor: {
                do {
                    return try await UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound])
                } catch {
                    return false
                }
            },
            notificationsStatusAccessor: {
                await withUnsafeContinuation { continuation in
                    UNUserNotificationCenter.current().getNotificationSettings { settings in
                        continuation.resume(returning: settings.authorizationStatus)
                    }
                }
            }
        )
    }
}

extension DevicePermissionsHandler: DevicePermissionsHandling {
    
    func requestPhotoLibraryAccessPermissions() async -> Bool {
        let level = await photoAccessor(.MEGAAccessLevel)
        return level == .authorized || level == .limited
    }
    
    func requestPermission(for mediaType: AVMediaType) async -> Bool {
        await mediaAccessor(mediaType)
    }
    
    func requestContactsPermissions() async -> Bool {
        await contactsAccessor()
    }
    
    func requestNotificationsPermission() async -> Bool {
        await notificationsAccessor()
    }
    
    // readings current status of authorization
    
    func notificationPermissionStatus() async -> UNAuthorizationStatus {
        await notificationsStatusAccessor()
    }
    
    var photoLibraryAuthorizationStatus: PHAuthorizationStatus {
        photoStatusAccessor(.MEGAAccessLevel)
    }
    
    var shouldAskForAudioPermissions: Bool {
        mediaStatusAccessor(.audio) == .notDetermined
    }
    
    var shouldAskForVideoPermissions: Bool {
        mediaStatusAccessor(.video) == .notDetermined
    }
    
    var shouldAskForPhotosPermissions: Bool {
        photoLibraryAuthorizationStatus == .notDetermined
    }
    
    var hasAuthorizedAccessToPhotoAlbum: Bool {
        photoLibraryAuthorizationStatus == .authorized
    }
    
    var contactsAuthorizationStatus: CNAuthorizationStatus {
        contactStatusAccessor()
    }
    
    var shouldAskForContactsPermissions: Bool {
        contactsAuthorizationStatus == .notDetermined
    }
    
    func shouldAskForNotificationPermission() async -> Bool {
        await notificationsStatusAccessor() == .notDetermined
    }
    
    var isVideoPermissionAuthorized: Bool {
        mediaStatusAccessor(.video) == .authorized
    }
    
    var audioPermissionAuthorizationStatus: AVAuthorizationStatus {
        mediaStatusAccessor(.audio)
    }
}
