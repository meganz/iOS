import AVFoundation
@testable import MEGAPermissions
import MEGASwift
import Photos
import UserNotifications
import XCTest

final class DevicePermissionsHandlerTests: XCTestCase {
    
    class Harness: @unchecked Sendable {
        lazy var sut: DevicePermissionsHandler = .init(
            mediaAccessor: { [unowned self] mediaType in
                self.$passedInAccessorMediaTypes.mutate { mediaTypes in
                    mediaTypes.append(mediaType)
                }
                return self.accessorMediaTypePermissionStateToReturn
            },
            mediaStatusAccessor: { [unowned self] status in
                self.$mediaStatusAccessorPassedInValues.mutate { values in
                    values.append(status)
                }
                return self.mediaStatusAccessorValueToReturn
            },
            photoAccessor: { [unowned self] accessLevel in
                self.$passedInRequestedPhotoAccessLevels.mutate { accessLevels in
                    accessLevels.append(accessLevel)
                }
                return self.photoAuthorizationStatusToReturn
            },
            photoStatusAccessor: { [unowned self] level in
                self.$photoStatusAccessorPassedInValues.mutate { levels in
                    levels.append(level)
                }
                return self.photoStatusAccessorValueToReturn
            },
            notificationsAccessor: { [unowned self] in
                self.$notificationAccessorCallCount.mutate { $0 += 1 }
                return self.notificationAccessorValueToReturn
            },
            notificationsStatusAccessor: { [unowned self] in
                self.$notificationsStatusAccessorCallCount.mutate { $0 += 1 }
                return self.notificationsStatusAccessorValueToReturn
            }
        )
        
        @Atomic
        var passedInAccessorMediaTypes: [AVMediaType] = []
        let accessorMediaTypePermissionStateToReturn: Bool
        
        @Atomic
        var passedInRequestedPhotoAccessLevels: [PHAccessLevel] = []
        let photoAuthorizationStatusToReturn: PHAuthorizationStatus
        
        @Atomic
        var notificationAccessorCallCount = 0
        let notificationAccessorValueToReturn: Bool
        
        @Atomic
        var notificationsStatusAccessorCallCount = 0
        let notificationsStatusAccessorValueToReturn: UNAuthorizationStatus
        
        @Atomic
        var photoStatusAccessorPassedInValues: [PHAccessLevel] = []
        let photoStatusAccessorValueToReturn: PHAuthorizationStatus
        
        @Atomic
        var mediaStatusAccessorPassedInValues: [AVMediaType] = []
        let mediaStatusAccessorValueToReturn: AVAuthorizationStatus
        
        init(
            accessorMediaTypePermissionStateToReturn: Bool = false,
            photoAuthorizationStatusToReturn: PHAuthorizationStatus = .notDetermined,
            notificationAccessorValueToReturn: Bool = false,
            notificationsStatusAccessorValueToReturn: UNAuthorizationStatus = .notDetermined,
            photoStatusAccessorValueToReturn: PHAuthorizationStatus = .notDetermined,
            mediaStatusAccessorValueToReturn: AVAuthorizationStatus = .notDetermined
        ) {
            self.accessorMediaTypePermissionStateToReturn = accessorMediaTypePermissionStateToReturn
            self.photoAuthorizationStatusToReturn = photoAuthorizationStatusToReturn
            self.notificationAccessorValueToReturn = notificationAccessorValueToReturn
            self.notificationsStatusAccessorValueToReturn = notificationsStatusAccessorValueToReturn
            self.photoStatusAccessorValueToReturn = photoStatusAccessorValueToReturn
            self.mediaStatusAccessorValueToReturn = mediaStatusAccessorValueToReturn
        }
    }
    
    func testRequestPhotoLibraryAccessPermissions_whenAuthorized_returnTrue() async throws {
        let harness = Harness(photoAuthorizationStatusToReturn: .authorized)
        let hasPermission = await harness.sut.requestPhotoLibraryAccessPermissions()
        XCTAssertTrue(hasPermission)
        XCTAssertEqual(harness.passedInRequestedPhotoAccessLevels, [.MEGAAccessLevel])
    }
    
    func testRequestPhotoLibraryAccessPermissions_whenLimited_returnTrue() async throws {
        let harness = Harness(photoAuthorizationStatusToReturn: .limited)
        let hasPermission = await harness.sut.requestPhotoLibraryAccessPermissions()
        XCTAssertTrue(hasPermission)
    }
    
    func testRequestPhotoLibraryAccessPermissions_whenNotDetermined_returnFalse() async throws {
        let harness = Harness(photoAuthorizationStatusToReturn: .notDetermined)
        let hasPermission = await harness.sut.requestPhotoLibraryAccessPermissions()
        XCTAssertFalse(hasPermission)
    }
    
    func testRequestPhotoLibraryAccessPermissions_whenRestricted_returnFalse() async throws {
        let harness = Harness(photoAuthorizationStatusToReturn: .restricted)
        let hasPermission = await harness.sut.requestPhotoLibraryAccessPermissions()
        XCTAssertFalse(hasPermission)
    }
    
    func testRequestPhotoLibraryAccessPermissions_whenDenied_returnFalse() async throws {
        let harness = Harness(photoAuthorizationStatusToReturn: .restricted)
        let hasPermission = await harness.sut.requestPhotoLibraryAccessPermissions()
        XCTAssertFalse(hasPermission)
    }
    
    func testRequestPermissionMediaType_whenPassedInType_returnCorrectValueTrue() async throws {
        let harness = Harness(accessorMediaTypePermissionStateToReturn: true)
        let hasPermission = await harness.sut.requestPermission(for: .audio)
        XCTAssertTrue(hasPermission)
        XCTAssertEqual(harness.passedInAccessorMediaTypes, [.audio])
        
    }
    
    func testRequestPermissionMediaType_whenPassedInType_returnCorrectValueFalse() async throws {
        let harness = Harness(accessorMediaTypePermissionStateToReturn: false)
        let hasPermission = await harness.sut.requestPermission(for: .video)
        XCTAssertEqual(harness.passedInAccessorMediaTypes, [.video])
        XCTAssertFalse(hasPermission)
        
    }
    
    func testRequestNotificationsPermission_returnsTrue() async throws {
        let harness = Harness(notificationAccessorValueToReturn: true)
        let hasPermission = await harness.sut.requestNotificationsPermission()
        XCTAssertEqual(harness.notificationAccessorCallCount, 1)
        XCTAssertTrue(hasPermission)
    }
    
    func testRequestNotificationsPermission_returnsFalse() async throws {
        let harness = Harness(notificationAccessorValueToReturn: false)
        let hasPermission = await harness.sut.requestNotificationsPermission()
        XCTAssertEqual(harness.notificationAccessorCallCount, 1)
        XCTAssertFalse(hasPermission)
    }
    
    func testReadingNotificationPermissionStatus_returnsCorrectValueAuthorized() async throws {
        let harness = Harness(notificationsStatusAccessorValueToReturn: .authorized)
        let status = await harness.sut.notificationPermissionStatus()
        XCTAssertEqual(harness.notificationsStatusAccessorCallCount, 1)
        XCTAssertEqual(status, .authorized)
    }
    
    func testReadingNotificationPermissionStatus_returnsCorrectValueDenied() async throws {
        let harness = Harness(notificationsStatusAccessorValueToReturn: .denied)
        let status = await harness.sut.notificationPermissionStatus()
        XCTAssertEqual(harness.notificationsStatusAccessorCallCount, 1)
        XCTAssertEqual(status, .denied)
    }
    
    func testphotoLibraryAuthorizationStatus_returnsCorrectValue_authorized() async throws {
        let harness = Harness(photoStatusAccessorValueToReturn: .authorized)
        let status = harness.sut.photoLibraryAuthorizationStatus
        XCTAssertEqual(harness.photoStatusAccessorPassedInValues, [.MEGAAccessLevel])
        XCTAssertEqual(status, .authorized)
    }
    
    func testphotoLibraryAuthorizationStatus_returnsCorrectValue_restricted() async throws {
        let harness = Harness(photoStatusAccessorValueToReturn: .restricted)
        let status = harness.sut.photoLibraryAuthorizationStatus
        XCTAssertEqual(harness.photoStatusAccessorPassedInValues, [.MEGAAccessLevel])
        XCTAssertEqual(status, .restricted)
    }
    
    func testShouldAskForAudioPermissions_isNotDetermined_returnTrue() async throws {
        let harness = Harness(mediaStatusAccessorValueToReturn: .notDetermined)
        let shouldAsk = harness.sut.shouldAskForAudioPermissions
        XCTAssertEqual(harness.mediaStatusAccessorPassedInValues, [.audio])
        XCTAssertTrue(shouldAsk)
    }
    
    func testShouldAskForAudioPermissions_isDenied_returnFalse() async throws {
        let harness = Harness(mediaStatusAccessorValueToReturn: .denied)
        let shouldAsk = harness.sut.shouldAskForAudioPermissions
        XCTAssertEqual(harness.mediaStatusAccessorPassedInValues, [.audio])
        XCTAssertFalse(shouldAsk)
    }
    
    func testShouldAskForAudioPermissions_isAuthorized_returnFalse() async throws {
        let harness = Harness(mediaStatusAccessorValueToReturn: .authorized)
        let shouldAsk = harness.sut.shouldAskForAudioPermissions
        XCTAssertEqual(harness.mediaStatusAccessorPassedInValues, [.audio])
        XCTAssertFalse(shouldAsk)
    }
    
    func testShouldAskForVideoPermissions_isNotDetermined_returnTrue() async throws {
        let harness = Harness(mediaStatusAccessorValueToReturn: .notDetermined)
        let shouldAsk = harness.sut.shouldAskForVideoPermissions
        XCTAssertEqual(harness.mediaStatusAccessorPassedInValues, [.video])
        XCTAssertTrue(shouldAsk)
    }
    
    func testShouldAskForVideoPermissions_isDenied_returnFalse() async throws {
        let harness = Harness(mediaStatusAccessorValueToReturn: .denied)
        let shouldAsk = harness.sut.shouldAskForVideoPermissions
        XCTAssertEqual(harness.mediaStatusAccessorPassedInValues, [.video])
        XCTAssertFalse(shouldAsk)
    }
    
    func testShouldAskForVideoPermissions_isAuthorized_returnFalse() async throws {
        let harness = Harness(mediaStatusAccessorValueToReturn: .authorized)
        let shouldAsk = harness.sut.shouldAskForVideoPermissions
        XCTAssertEqual(harness.mediaStatusAccessorPassedInValues, [.video])
        XCTAssertFalse(shouldAsk)
    }
    
    func testShouldAskForPhotoPermissions_isNotDetermined_returnTrue() async throws {
        let harness = Harness(photoStatusAccessorValueToReturn: .notDetermined)
        let shouldAsk = harness.sut.shouldAskForPhotosPermissions
        XCTAssertEqual(harness.photoStatusAccessorPassedInValues, [.MEGAAccessLevel])
        XCTAssertTrue(shouldAsk)
    }
    
    func testShouldAskForPhotoPermissions_isDenied_returnFalse() async throws {
        let harness = Harness(photoStatusAccessorValueToReturn: .denied)
        let shouldAsk = harness.sut.shouldAskForPhotosPermissions
        XCTAssertEqual(harness.photoStatusAccessorPassedInValues, [.MEGAAccessLevel])
        XCTAssertFalse(shouldAsk)
    }
    
    func testShouldAskForPhotoPermissions_isAuthorized_returnFalse() async throws {
        let harness = Harness(photoStatusAccessorValueToReturn: .authorized)
        let shouldAsk = harness.sut.shouldAskForPhotosPermissions
        XCTAssertEqual(harness.photoStatusAccessorPassedInValues, [.MEGAAccessLevel])
        XCTAssertFalse(shouldAsk)
    }
    
    func testHasAuthorizedAccessToPhotoAlbum_isAuthorized_returnTrue() async throws {
        let harness = Harness(photoStatusAccessorValueToReturn: .authorized)
        let hasAuthorization = harness.sut.hasAuthorizedAccessToPhotoAlbum
        XCTAssertEqual(harness.photoStatusAccessorPassedInValues, [.MEGAAccessLevel])
        XCTAssertTrue(hasAuthorization)
    }
    
    func testHasAuthorizedAccessToPhotoAlbum_isDenied_returnFalse() async throws {
        let harness = Harness(photoStatusAccessorValueToReturn: .denied)
        let hasAuthorization = harness.sut.hasAuthorizedAccessToPhotoAlbum
        XCTAssertEqual(harness.photoStatusAccessorPassedInValues, [.MEGAAccessLevel])
        XCTAssertFalse(hasAuthorization)
    }
    
    func testShouldAskForNotificationPermission_isNotDetermined_returnTrue() async throws {
        let harness = Harness(notificationsStatusAccessorValueToReturn: .notDetermined)
        let shouldAsk = await harness.sut.shouldAskForNotificationPermission()
        XCTAssertEqual(harness.notificationsStatusAccessorCallCount, 1)
        XCTAssertTrue(shouldAsk)
    }
    
    func testShouldAskForNotificationPermission_isAuthorized_returnTrue() async throws {
        let harness = Harness(notificationsStatusAccessorValueToReturn: .authorized)
        let shouldAsk = await harness.sut.shouldAskForNotificationPermission()
        XCTAssertEqual(harness.notificationsStatusAccessorCallCount, 1)
        XCTAssertFalse(shouldAsk)
    }
    
    func testShouldAskForNotificationPermission_isDenied_returnTrue() async throws {
        let harness = Harness(notificationsStatusAccessorValueToReturn: .denied)
        let shouldAsk = await harness.sut.shouldAskForNotificationPermission()
        XCTAssertEqual(harness.notificationsStatusAccessorCallCount, 1)
        XCTAssertFalse(shouldAsk)
    }
    
    func testAudioPermissionAuthorizationStatus_isNotDetermined_returnCorrectValue() async throws {
        let harness = Harness(mediaStatusAccessorValueToReturn: .notDetermined)
        let status = harness.sut.audioPermissionAuthorizationStatus
        XCTAssertEqual(harness.mediaStatusAccessorPassedInValues, [.audio])
        XCTAssertEqual(status, .notDetermined)
    }
    
    func testAudioPermissionAuthorizationStatus_isAuthorized_returnCorrectValue() async throws {
        let harness = Harness(mediaStatusAccessorValueToReturn: .authorized)
        let status = harness.sut.audioPermissionAuthorizationStatus
        XCTAssertEqual(harness.mediaStatusAccessorPassedInValues, [.audio])
        XCTAssertEqual(status, .authorized)
    }
    
    func testAudioPermissionAuthorizationStatus_isDenied_returnCorrectValue() async throws {
        let harness = Harness(mediaStatusAccessorValueToReturn: .denied)
        let status = harness.sut.audioPermissionAuthorizationStatus
        XCTAssertEqual(harness.mediaStatusAccessorPassedInValues, [.audio])
        XCTAssertEqual(status, .denied)
    }
    
    func testIsVideoPermissionAuthorized_isAuthorized_returnTrue() async throws {
        let harness = Harness(mediaStatusAccessorValueToReturn: .authorized)
        let authorized = harness.sut.isVideoPermissionAuthorized
        XCTAssertEqual(harness.mediaStatusAccessorPassedInValues, [.video])
        XCTAssertTrue(authorized)
    }
    
    func testIsVideoPermissionAuthorized_isDenied_returnTrue() async throws {
        let harness = Harness(mediaStatusAccessorValueToReturn: .denied)
        let authorized = harness.sut.isVideoPermissionAuthorized
        XCTAssertEqual(harness.mediaStatusAccessorPassedInValues, [.video])
        XCTAssertFalse(authorized)
    }
    
    func testNotificationOptions_HaveAlertBadgeAndSound() {
        XCTAssertEqual(DevicePermissionsHandler.notificationOptions, [.alert, .sound, .badge])
    }
}
