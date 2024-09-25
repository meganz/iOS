import MEGADomain
import MEGASdk
import MEGASDKRepo
import MEGASDKRepoMock
import XCTest

final class UserUpdateProviderTests: XCTestCase {
    
    func testUserUpdates_onSDKUserChangeEvent_expectUserEntity() async {
        let myUser = MockUser(handle: 1000)
        let sdk = MockSdk(myUser: myUser, shouldListGlobalDelegates: true)
        let sut = sut(sdk: sdk)
        
        let userUpdateExpectation = expectation(description: "Expected a user update")
        let task = await expectationTaskStarted { taskStartedExpectation in
            taskStartedExpectation.fulfill()
            for await _ in sut.userUpdates {
                userUpdateExpectation.fulfill()
            }
        }
        
        let userList = MockUserList(users: [MockUser(handle: 1000)])
        
        sdk.simulateOnUserUpdate(userList)
        
        await fulfillment(of: [userUpdateExpectation], timeout: 1)
        
        task.cancel()
    }
    
    func testUserUpdatesFilteredBy_whenFilteringByCCPref_expectOnlyCCPrefChangeToTriggerEvent() async {
        let myUser = MockUser(handle: 1000)
        let sdk = MockSdk(myUser: myUser, shouldListGlobalDelegates: true)
        let sut = sut(sdk: sdk)
        
        let userUpdateExpectation = expectation(description: "Expected a user update for ccPref change type only")
        let task = await expectationTaskStarted { taskStartedExpectation in
            let sequence = sut.userUpdates(filterBy: .CCPrefs)
            taskStartedExpectation.fulfill()
            for await user in sequence {
                XCTAssertEqual(user.changes, .CCPrefs)
                userUpdateExpectation.fulfill()
            }
        }
        
        MEGAUserChangeType.all
            .forEach { changeType in
                let userList = MockUserList(users: [MockUser(handle: 1000, changes: changeType)])
                sdk.simulateOnUserUpdate(userList)
            }
        
        await fulfillment(of: [userUpdateExpectation], timeout: 5)
        
        task.cancel()
    }
}

extension UserUpdateProviderTests {
    func sut(sdk: MockSdk) -> UserUpdateProvider {
        UserUpdateProvider(sdk: sdk)
    }
}


fileprivate extension MEGAUserChangeType {
    static var all: [MEGAUserChangeType] {
        [
            .auth,
            .lstint,
            .avatar,
            .firstname,
            .lastname,
            .email,
            .keyring,
            .country,
            .birthday,
            .pubKeyEd255,
            .pubKeyCu255,
            .sigPubKeyRsa,
            .sigPubKeyCu255,
            .language,
            .pwdReminder,
            .disableVersions,
            .contactLinkVerification,
            .richPreviews,
            .rubbishTime,
            .storageState,
            .geolocation,
            .cameraUploadsFolder,
            .myChatFilesFolder,
            .pushSettings,
            .userAlias,
            .unshareableKey,
            .deviceNames,
            .backupFolder,
            .cookieSetting,
            .noCallKit,
            .appsPrefs,
            .ccPrefs
        ]
    }
}
