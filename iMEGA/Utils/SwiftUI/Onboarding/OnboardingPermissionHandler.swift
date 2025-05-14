import MEGAAnalyticsiOS
import MEGAPermissions
import MEGAPresentation

protocol OnboardingPermissionHandling: Sendable {
    func requestPermission() async -> Bool
    func screenViewEvent() -> any EventIdentifier
    func enablePermissionAnalyticsEvent() -> any EventIdentifier
    func skipPermissionAnalyticsEvent() -> any EventIdentifier
    func permissionResultAnalyticsEvent() async -> (any EventIdentifier)?
}

struct OnboardingPermissionHandler: OnboardingPermissionHandling {
    enum PermissionType {
        case notifications
        case photos
    }
    private let devicePermissionHandler: any DevicePermissionsHandling
    private let permissionType: PermissionType

    init(
        permissionType: PermissionType,
        devicePermissionHandler: some DevicePermissionsHandling = DevicePermissionsHandler.makeHandler(),
    ) {
        self.permissionType = permissionType
        self.devicePermissionHandler = devicePermissionHandler
    }

    func requestPermission() async -> Bool {
        switch permissionType {
        case .notifications:
            await devicePermissionHandler.requestNotificationsPermission()
        case .photos:
            await devicePermissionHandler.requestPhotoLibraryAccessPermissions()
        }
    }

    func screenViewEvent() -> any EventIdentifier {
        switch permissionType {
        case .notifications:
            NotificationsCTAScreenEvent()
        case .photos:
            CameraBackupsCTAScreenEvent()
        }
    }

    func enablePermissionAnalyticsEvent() -> any EventIdentifier {
        switch permissionType {
        case .notifications:
            EnableNotificationsCTAButtonPressedEvent()
        case .photos:
            EnableCameraBackupsCTAButtonPressedEvent()
        }
    }

    func skipPermissionAnalyticsEvent() -> any EventIdentifier {
        switch permissionType {
        case .notifications:
            SkipNotificationsCTAButtonPressedEvent()
        case .photos:
            SkipCameraBackupsCTAButtonPressedEvent()
        }
    }

    func permissionResultAnalyticsEvent() async -> (any EventIdentifier)? {
        switch permissionType {
        case .notifications:
            switch await devicePermissionHandler.notificationPermissionStatus() {
            case .authorized: AllowNotificationsCTAButtonPressedEvent()
            case .denied: DontAllowNotificationsCTAButtonPressedEvent()
            default: nil
            }
        case .photos:
            switch devicePermissionHandler.photoLibraryAuthorizationStatus {
            case .authorized: FullAccessCameraBackupsCTAButtonPressedEvent()
            case .limited: LimitedAccessCameraBackupsCTAButtonPressedEvent()
            case .denied: DontAllowCameraBackupsCTAButtonPressedEvent()
            default: nil
            }
        }
    }
}
