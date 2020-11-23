import XCTest
@testable import MEGA

class HomeAvatarViewModelTests: XCTestCase {

    func testUseLocalCachedAvatarIfFound() throws {
        let notificationUseCase = MEGANotificationUseCase(userAlertsClient: .doNothing)

        let mockLocalCachedImage = UIImage(ciImage: CIImage(color: CIColor.red))
        let mockRemoteImage = UIImage(ciImage: CIImage(color: CIColor.green))

        let avatarFileSysteClient: FileSystemImageCacheClient = .found(mockLocalCachedImage)
        let avatarRemoteClient: AvatarSDKClient = .found(mockRemoteImage)

        // Will return local cached avatar image and remote avatar image
        let avatarUseCase = MEGAavatarUseCase(
            megaAvatarClient: avatarRemoteClient,
            avatarFileSystemClient: avatarFileSystemClient,
            megaUserClient: .foundUser
        )

        // Will generate an avatar image.
        let avatarGeneratingUseCase = MEGAAavatarGeneratingUseCaseMock()

        let viewModelUT = HomeAccountViewModel(
            megaNotificationUseCase: notificationUseCase,
            megaAvatarUseCase: avatarUseCase,
            megaAavatarGeneratingUseCase: avatarGeneratingUseCase
        )

        let expect = expectation(description: "Async load")
        expect.expectedFulfillmentCount = 1 // Only invoke once for local cached image
        viewModelUT.notifyUpdate = { output in
            let foundImage = output.avatarImage
            let resizedOriginalImageData = mockLocalCachedImage.resize(to: CGSize(width: 28, height: 28)).withRoundedCorners().pngData()
            let outputImageData = foundImage.pngData()
            XCTAssertEqual(resizedOriginalImageData, outputImageData)
            expect.fulfill()
        }

        viewModelUT.inputs.viewIsReady()
        wait(for: [expect], timeout: 0.3)
    }

    func testUseGeneratedAvatar_IfNoLocalCachedAvatar_AndNoRemoteAvatar() throws {
        let notificationUseCase = MEGANotificationUseCase(userAlertsClient: .doNothing)

        // Will return NO local cached avatar image and NO remote avatar image
        let avatarUseCase = MEGAavatarUseCase(
            megaAvatarClient: .foundNil,
            avatarFileSystemClient: .foundNil,
            megaUserClient: .foundUser
        )

        // Will generate an avatar image.
        let avatarGeneratingUseCase = MEGAAavatarGeneratingUseCaseMock()

        let viewModelUT = HomeAccountViewModel(
            megaNotificationUseCase: notificationUseCase,
            megaAvatarUseCase: avatarUseCase,
            megaAavatarGeneratingUseCase: avatarGeneratingUseCase
        )

        let expect = expectation(description: "Async load")
        // Only invoke once for local cached image
        // In `loadAvatarImage` function in AccountViewModel, the generated avatar is temporary, and once a
        // remote avatar image loaded, the temp one will be removed, and a new update call trigged.
        // In this test case, we are simulating a case that there is no remote avatar image available, so the
        // callback function `notifyUpdate` is called *ONCE* ONLY.
        expect.expectedFulfillmentCount = 1

        viewModelUT.notifyUpdate = { output in
            let foundImage = output.avatarImage
            XCTAssertNotNil(foundImage)
            expect.fulfill()
        }

        viewModelUT.inputs.viewIsReady()
        wait(for: [expect], timeout: 0.3)
    }

    func testUseRemoteAvatar_GivenNoLocalCachedAvatar_EvenHasGeneratedImage() throws {
        let notificationUseCase = MEGANotificationUseCase(userAlertsClient: .doNothing)

        let mockRemoteImage = UIImage(ciImage: CIImage(color: CIColor.green))

        let avatarRemoteClient: SDKAvatarClient = .found(mockRemoteImage)

        // Will return NO local cached avatar image but YES remote avatar image
        let avatarUseCase = MEGAavatarUseCase(
            megaAvatarClient: avatarRemoteClient,
            avatarFileSystemClient: .foundNil,
            megaUserClient: .foundUser
        )

        // Will generate an avatar image.
        let avatarGeneratingUseCase = MEGAAavatarGeneratingUseCaseMock()

        let viewModelUT = HomeAccountViewModel(
            megaNotificationUseCase: notificationUseCase,
            megaAvatarUseCase: avatarUseCase,
            megaAavatarGeneratingUseCase: avatarGeneratingUseCase
        )

        let expect = expectation(description: "Async load")
        // Invoke TWICE for local cached image
        // In `loadAvatarImage` function in AccountViewModel, the generated avatar is temporary, and once a
        // remote avatar image loaded, the temp one will be removed, and a new update call trigged.
        // In this test case, we are simulating a case that there IS an remote avatar image available, so the
        // callback function `notifyUpdate` is be called *TWICE*.
        expect.expectedFulfillmentCount = 2

        viewModelUT.notifyUpdate = { output in
            let foundImage = output.avatarImage
            XCTAssertNotNil(foundImage)
            expect.fulfill()
        }

        viewModelUT.inputs.viewIsReady()
        wait(for: [expect], timeout: 1)
    }

    func testLoadUserNotifications_WhenSDKNotificationUpdate() throws {

        let notificationUseCase = MEGANotificationUseCaseMock()

        // Will return local cached avatar image and remote avatar image
        let avatarUseCase = MEGAavatarUseCase(
            megaAvatarClient: .foundNil,
            avatarFileSystemClient: .foundNil,
            megaUserClient: .foundNil
        )

        // Will generate an avatar image.
        let avatarGeneratingUseCase = MEGAAavatarGeneratingUseCase(
            storeUserClient: .foundAUser,
            megaAvatarClient: .foundImage,
            megaUserClient: .foundUser
        )

        let viewModelUT = HomeAccountViewModel(
            megaNotificationUseCase: notificationUseCase,
            megaAvatarUseCase: avatarUseCase,
            megaAavatarGeneratingUseCase: avatarGeneratingUseCase
        )

        let expect = expectation(description: "Will eventually load notification number")

        viewModelUT.notifyUpdate = { output in
            // 5, as alerts are 3 + contact request 2
            if output.notificationNumber == "5" {
                expect.fulfill()
            }
        }

        viewModelUT.inputs.viewIsReady()
        notificationUseCase.alertsAction([])
        notificationUseCase.contactRequestAction([])

        wait(for: [expect], timeout: 10) //
    }
}

struct MEGAAavatarGeneratingUseCaseMock: MEGAAvatarGeneratingUseCaseProtocol {

    func avatarName() -> String? {
        "J"
    }

    func avatarBackgroundColorHex() -> String? {
        "#FFCC66"
    }
}

class MEGANotificationUseCaseMock: MEGANotificationUseCaseProtocol {

    var alertsAction: (([UserAlert]) -> Void)!

    var contactRequestAction: (([ContactRequest]) -> Void)!

    func relevantAndNotSeenAlerts() -> [UserAlert]? {
        return [
            .random,
            .random,
            .random
        ]
    }

    func incomingContactRequest() -> [ContactRequest] {
        return [
            .random,
            .random
        ]
    }

    func observeUserRelevantAndNotSeenAlerts(with callback: @escaping ([UserAlert]) -> Void) {
        self.alertsAction = callback
    }

    func observeUserContactRequests(with callback: @escaping ([ContactRequest]) -> Void) {
        self.contactRequestAction = callback
    }
}
