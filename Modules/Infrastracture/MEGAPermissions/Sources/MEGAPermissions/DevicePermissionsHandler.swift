import AVKit
import Photos
import UIKit

extension PHAccessLevel {
    // app requests read/write access
    static let MEGAAccessLevel: PHAccessLevel = .readWrite
}

public struct DevicePermissionsHandler {
    
    public init(
        mediaAccessor: @escaping @Sendable (AVMediaType) async -> Bool,
        mediaStatusAccessor: @escaping @Sendable (AVMediaType) -> AVAuthorizationStatus,
        photoAccessor: @escaping @Sendable (PHAccessLevel) async -> PHAuthorizationStatus,
        photoStatusAccessor: @escaping @Sendable (PHAccessLevel) -> PHAuthorizationStatus,
        notificationsAccessor: @escaping @Sendable () async -> Bool,
        notificationsStatusAccessor: @escaping @Sendable () async -> UNAuthorizationStatus
    ) {
        self.mediaAccessor = mediaAccessor
        self.mediaStatusAccessor = mediaStatusAccessor
        self.photoAccessor = photoAccessor
        self.photoStatusAccessor = photoStatusAccessor
        self.notificationsAccessor = notificationsAccessor
        self.notificationsStatusAccessor = notificationsStatusAccessor
    }
    
    private let mediaAccessor: @Sendable (AVMediaType) async -> Bool
    private let mediaStatusAccessor: @Sendable (AVMediaType) -> AVAuthorizationStatus
    
    private let photoAccessor: @Sendable (PHAccessLevel) async -> PHAuthorizationStatus
    private let photoStatusAccessor: @Sendable (PHAccessLevel) -> PHAuthorizationStatus
    
    private let notificationsAccessor: @Sendable () async -> Bool
    private let notificationsStatusAccessor: @Sendable () async -> UNAuthorizationStatus
    
}

public extension DevicePermissionsHandler {
    static func makeHandler() -> Self {
        .init(
            mediaAccessor: { await AVCaptureDevice.requestAccess(for: $0) },
            mediaStatusAccessor: { AVCaptureDevice.authorizationStatus(for: $0) },
            photoAccessor: { await PHPhotoLibrary.requestAuthorization(for: $0) },
            photoStatusAccessor: { PHPhotoLibrary.authorizationStatus(for: $0) },
            notificationsAccessor: {
                do {
                    return try await UNUserNotificationCenter.current().requestAuthorization(options: notificationOptions)
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
    
    static var notificationOptions: UNAuthorizationOptions {
        [.badge, .sound, .alert]
    }
}

extension DevicePermissionsHandler: DevicePermissionsHandling {

    /// This request readWrite permission
    public func requestPhotoLibraryAccessPermissions() async -> Bool {
        let level = await photoAccessor(.MEGAAccessLevel)
        return level == .authorized || level == .limited
    }

    /// This request addOnly permission
    public func requestPhotoLibraryAddOnlyPermissions() async -> Bool {
        let level = await photoAccessor(.addOnly)
        return level == .authorized || level == .limited
    }

    public func requestPermission(for mediaType: AVMediaType) async -> Bool {
        await mediaAccessor(mediaType)
    }
    
    public func requestNotificationsPermission() async -> Bool {
        await notificationsAccessor()
    }
    
    // readings current status of authorization
    
    public func notificationPermissionStatus() async -> UNAuthorizationStatus {
        await notificationsStatusAccessor()
    }
    
    public var photoLibraryAuthorizationStatus: PHAuthorizationStatus {
        photoStatusAccessor(.MEGAAccessLevel)
    }
    
    public var shouldAskForAudioPermissions: Bool {
        mediaStatusAccessor(.audio) == .notDetermined
    }
    
    public var shouldAskForVideoPermissions: Bool {
        mediaStatusAccessor(.video) == .notDetermined
    }
    
    public var shouldAskForPhotosPermissions: Bool {
        photoLibraryAuthorizationStatus == .notDetermined
    }
    
    public var hasAuthorizedAccessToPhotoAlbum: Bool {
        photoLibraryAuthorizationStatus == .authorized
    }

    public func shouldAskForNotificationPermission() async -> Bool {
        await notificationsStatusAccessor() == .notDetermined
    }
    
    public var isVideoPermissionAuthorized: Bool {
        mediaStatusAccessor(.video) == .authorized
    }
    
    public var audioPermissionAuthorizationStatus: AVAuthorizationStatus {
        mediaStatusAccessor(.audio)
    }
}
