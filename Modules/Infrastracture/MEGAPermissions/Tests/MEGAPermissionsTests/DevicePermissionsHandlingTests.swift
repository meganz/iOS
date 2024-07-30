import MEGAPermissionsMock
import XCTest

// testing protocol extension method, not the mock itself
final class DevicePermissionsHandlingTests: XCTestCase {
    func testShouldSetupPermissions_anyIsTrue_returnsTrue_elseFalse() async {
        struct Scenario {
            let inputs: (Bool, Bool, Bool, Bool)
            let output: Bool
        }
        let scenarios: [Scenario] = [
            .init(inputs: (false, false, false, false), output: false),
            .init(inputs: (true, false, false, false), output: true),
            .init(inputs: (false, true, false, false), output: true),
            .init(inputs: (false, false, true, false), output: true),
            .init(inputs: (false, false, false, true), output: true)
        ]
        for scenario in scenarios {
            let handler = MockDevicePermissionHandler()
            handler.shouldAskForAudioPermissions = scenario.inputs.0
            handler.shouldAskForVideoPermissions = scenario.inputs.1
            handler.shouldAskForPhotosPermissions = scenario.inputs.2
            handler.shouldAskForNotificationPermissionsValueToReturn = scenario.inputs.3
            let shouldSetup = await handler.shouldSetupPermissions()
            XCTAssertEqual(shouldSetup, scenario.output)
        }
    }
    
    func testIsPhotoLibraryAccessProhibited_returnTrue_ifRestricted() {
        let handler = MockDevicePermissionHandler()
        handler.photoLibraryAuthorizationStatus = .restricted
        XCTAssertTrue(handler.isPhotoLibraryAccessProhibited)
    }
    
    func testIsPhotoLibraryAccessProhibited_returnTrue_ifDenied() {
        let handler = MockDevicePermissionHandler()
        handler.photoLibraryAuthorizationStatus = .denied
        XCTAssertTrue(handler.isPhotoLibraryAccessProhibited)
    }
    
    func testIsPhotoLibraryAccessProhibited_returnFalse_ifAuthorized() {
        let handler = MockDevicePermissionHandler()
        handler.photoLibraryAuthorizationStatus = .authorized
        XCTAssertFalse(handler.isPhotoLibraryAccessProhibited)
    }
    
    func testIsPhotoLibraryAccessProhibited_returnFalse_ifLimited() {
        let handler = MockDevicePermissionHandler()
        handler.photoLibraryAuthorizationStatus = .limited
        XCTAssertFalse(handler.isPhotoLibraryAccessProhibited)
    }
    
    func testIsPhotoLibraryAccessProhibited_returnFalse_ifNotDetermined() {
        let handler = MockDevicePermissionHandler()
        handler.photoLibraryAuthorizationStatus = .notDetermined
        XCTAssertFalse(handler.isPhotoLibraryAccessProhibited)
    }
    
    func testIsAudioPermissionAuthorized_returnTrue_ifAuthorized() {
        let handler = MockDevicePermissionHandler()
        handler.audioPermissionAuthorizationStatus = .authorized
        XCTAssertTrue(handler.isAudioPermissionAuthorized)
    }
    
    func testIsAudioPermissionAuthorized_returnFalse_ifDenied() {
        let handler = MockDevicePermissionHandler()
        handler.audioPermissionAuthorizationStatus = .denied
        XCTAssertFalse(handler.isAudioPermissionAuthorized)
    }
    
    func testIsAudioPermissionAuthorized_returnFalse_ifRestricted() {
        let handler = MockDevicePermissionHandler()
        handler.audioPermissionAuthorizationStatus = .restricted
        XCTAssertFalse(handler.isAudioPermissionAuthorized)
    }
    
    func testIsAudioPermissionAuthorized_returnFalse_ifNotDetermined() {
        let handler = MockDevicePermissionHandler()
        handler.audioPermissionAuthorizationStatus = .notDetermined
        XCTAssertFalse(handler.isAudioPermissionAuthorized)
    }
}
