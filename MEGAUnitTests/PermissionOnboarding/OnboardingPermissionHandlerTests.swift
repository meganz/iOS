@testable import MEGA
import MEGAAnalytics
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGAPermissionsMock
import Testing

struct OnboardingPermissionHandlerTests {

    @Test("requestPermission should return correct value",
          arguments: [
            (OnboardingPermissionHandler.PermissionType.notifications, true),
            (.notifications, false),
            (.photos, true),
            (.photos, false)
          ]
    )
    func testRequestPermission(_ permissionType: OnboardingPermissionHandler.PermissionType, permissionGranted: Bool) async throws {
        let handler = MockDevicePermissionHandler(requestPhotoLibraryAccessPermissionsGranted: permissionGranted)
        handler.requestNotificationsPermissionToReturn = permissionGranted
        let sut = OnboardingPermissionHandler(permissionType: permissionType, devicePermissionHandler: handler)
        let result = await sut.requestPermission()
        #expect(result == permissionGranted)
    }

    @Test(
        "screenViewEvent should return correct unique identifier",
        arguments: [
            (OnboardingPermissionHandler.PermissionType.notifications, NotificationsCTAScreenEvent().uniqueIdentifier),
            (.photos, CameraBackupsCTAScreenEvent().uniqueIdentifier)
        ]
    )
    func testScreenViewEventType(_ permissionType: OnboardingPermissionHandler.PermissionType, expectedIdentifier: Int32) {
        let sut = OnboardingPermissionHandler(
            permissionType: permissionType, devicePermissionHandler: MockDevicePermissionHandler()
        )
        #expect(sut.screenViewEvent().uniqueIdentifier == expectedIdentifier)
    }

    @Test(
        "For .notifications permission, permissionResultAnalyticsEvent should return correct unique identifier",
        arguments: [
            (UNAuthorizationStatus.notDetermined, Optional<Int32>.none),
            (.authorized, AllowNotificationsCTAButtonPressedEvent().uniqueIdentifier),
            (.denied, DontAllowNotificationsCTAButtonPressedEvent().uniqueIdentifier)
        ])
    func testNotificationPermissionResultAnalyticsEvent(
        permissionStatus: UNAuthorizationStatus,
        expectedIdentifier: Int32?
    ) async {
        let handler = MockDevicePermissionHandler()
        handler.notificationPermissionStatusToReturn = permissionStatus
        let sut = OnboardingPermissionHandler(permissionType: .notifications, devicePermissionHandler: handler)
        let result = await sut.permissionResultAnalyticsEvent()
        #expect(result?.uniqueIdentifier == expectedIdentifier)
    }

    @Test(
        "For .photos permission, permissionResultAnalyticsEvent should return correct unique identifier",
        arguments: [
            (PHAuthorizationStatus.notDetermined, Optional<Int32>.none),
            (.authorized, FullAccessCameraBackupsCTAButtonPressedEvent().uniqueIdentifier),
            (.limited, LimitedAccessCameraBackupsCTAButtonPressedEvent().uniqueIdentifier),
            (.denied, DontAllowCameraBackupsCTAButtonPressedEvent().uniqueIdentifier)
        ])
    func testPhotoPermissionResultAnalyticsEvent(
        permissionStatus: PHAuthorizationStatus,
        expectedIdentifier: Int32?
    ) async {
        let handler = MockDevicePermissionHandler()
        handler.photoLibraryAuthorizationStatus = permissionStatus
        let sut = OnboardingPermissionHandler(permissionType: .photos, devicePermissionHandler: handler)
        let result = await sut.permissionResultAnalyticsEvent()
        #expect(result?.uniqueIdentifier == expectedIdentifier)
    }
}
