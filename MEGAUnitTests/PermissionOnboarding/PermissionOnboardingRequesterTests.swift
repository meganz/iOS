@testable import MEGA
import MEGAAppPresentationMock
import MEGAPermissionsMock
import Testing

struct PermissionOnboardingRequesterTests {
    @Test(arguments: [
        (PermissionOnboardingRequester.PermissionType.notifications, true),
        (.notifications, false),
        (.photos, true),
        (.photos, false)
    ])
    func testRequestPermission(
        permissionType: PermissionOnboardingRequester.PermissionType,
        permissionGranted: Bool
    ) async throws {
        let permissionHandler = MockDevicePermissionHandler(requestPhotoLibraryAccessPermissionsGranted: permissionGranted)
        permissionHandler.requestNotificationsPermissionToReturn = permissionGranted

        let requester = PermissionOnboardingRequester(
            permissionType: permissionType,
            devicePermissionHandler: permissionHandler
        )

        #expect(await requester.requestPermission() == permissionGranted)
    }
}
