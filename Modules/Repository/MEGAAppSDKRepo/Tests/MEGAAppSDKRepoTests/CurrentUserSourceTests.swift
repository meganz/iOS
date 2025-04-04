import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGASdk
import Testing
import XCTest

final class CurrentUserSourceTests: XCTestCase {
    func testUserFields_init_empty() {
        let source = CurrentUserSource(sdk: MockSdk())
        XCTAssertNil(source.currentUserHandle)
        XCTAssertNil(source.currentUserEmail)
        XCTAssertTrue(source.isGuest)
        XCTAssertFalse(source.isLoggedIn)
    }
    
    func testUserFields_init_nonEmpty() {
        let source = CurrentUserSource(sdk: MockSdk(myUser: MockUser(handle: 5, email: "abc@mega.nz"), isLoggedIn: 1))
        XCTAssertEqual(source.currentUserEmail, "abc@mega.nz")
        XCTAssertEqual(source.currentUserHandle, 5)
        XCTAssertFalse(source.isGuest)
        XCTAssertTrue(source.isLoggedIn)
    }
    
    func testUserFields_login_updateHandle() {
        let sdk = MockSdk()
        let source = CurrentUserSource(sdk: sdk)
        XCTAssertNil(source.currentUserHandle)
        XCTAssertNil(source.currentUserEmail)
        XCTAssertTrue(source.isGuest)
        XCTAssertFalse(source.isLoggedIn)
        
        sdk._myUser = MockUser(handle: 10, email: "hello@mega.nz")
        sdk._isLoggedIn = 1
        XCTAssertNil(source.currentUserHandle)
        XCTAssertNil(source.currentUserEmail)
        XCTAssertTrue(source.isGuest)
        XCTAssertFalse(source.isLoggedIn)
        
        NotificationCenter.default.post(name: .accountDidLogin, object: nil)
        let exp = expectation(description: "login")
        _ = XCTWaiter.wait(for: [exp], timeout: 0.01)
        XCTAssertEqual(source.currentUserHandle, 10)
        XCTAssertNil(source.currentUserEmail)
        XCTAssertTrue(source.isGuest)
    }
    
    func testUserFields_fetchNodes_updateEmail() {
        let sdk = MockSdk()
        let source = CurrentUserSource(sdk: sdk)
        XCTAssertNil(source.currentUserHandle)
        XCTAssertNil(source.currentUserEmail)
        XCTAssertTrue(source.isGuest)
        
        sdk._myUser = MockUser(handle: 10, email: "hello@mega.nz")
        XCTAssertNil(source.currentUserHandle)
        XCTAssertNil(source.currentUserEmail)
        XCTAssertTrue(source.isGuest)
        
        NotificationCenter.default.post(name: .accountDidFinishFetchNodes, object: nil)
        let exp = expectation(description: "login")
        _ = XCTWaiter.wait(for: [exp], timeout: 0.01)
        XCTAssertEqual(source.currentUserEmail, "hello@mega.nz")
        XCTAssertNil(source.currentUserHandle)
        XCTAssertFalse(source.isGuest)
        XCTAssertFalse(source.isLoggedIn)
    }
    
    func testUserFields_logout_empty() {
        let source = CurrentUserSource(sdk: MockSdk(myUser: MockUser(handle: 5, email: "abc@mega.nz"), isLoggedIn: 1))
        XCTAssertEqual(source.currentUserEmail, "abc@mega.nz")
        XCTAssertEqual(source.currentUserHandle, 5)
        XCTAssertFalse(source.isGuest)
        XCTAssertTrue(source.isLoggedIn)
        
        NotificationCenter.default.post(name: .accountDidLogout, object: nil)
        let exp = expectation(description: "logout")
        _ = XCTWaiter.wait(for: [exp], timeout: 0.01)
        XCTAssertNil(source.currentUserHandle)
        XCTAssertNil(source.currentUserEmail)
        XCTAssertTrue(source.isGuest)
        XCTAssertFalse(source.isLoggedIn)
        XCTAssertNil(source.accountDetails)
    }
    
    func testChangeEmail_notCurrentUser_noEmailChange() {
        let source = CurrentUserSource(sdk: MockSdk(myUser: MockUser(handle: 5, email: "abc@mega.nz")))
        XCTAssertEqual(source.currentUserEmail, "abc@mega.nz")
        XCTAssertEqual(source.currentUserHandle, 5)
        XCTAssertFalse(source.isGuest)
        
        NotificationCenter.default.post(name: .accountEmailDidChange, object: nil, userInfo: ["user": MockUser(handle: 4, email: "4@mega.nz")])
        let exp = expectation(description: "email")
        _ = XCTWaiter.wait(for: [exp], timeout: 0.01)
        XCTAssertEqual(source.currentUserEmail, "abc@mega.nz")
        XCTAssertEqual(source.currentUserHandle, 5)
        XCTAssertFalse(source.isGuest)
    }
    
    func testChangeEmail_currentUser_emailIsChanged() {
        let source = CurrentUserSource(sdk: MockSdk(myUser: MockUser(handle: 5, email: "abc@mega.nz")))
        XCTAssertEqual(source.currentUserEmail, "abc@mega.nz")
        XCTAssertEqual(source.currentUserHandle, 5)
        XCTAssertFalse(source.isGuest)
        
        NotificationCenter.default.post(name: .accountEmailDidChange, object: nil, userInfo: ["user": MockUser(handle: 5, email: "5@mega.nz")])
        let exp = expectation(description: "email")
        _ = XCTWaiter.wait(for: [exp], timeout: 0.01)
        XCTAssertEqual(source.currentUserEmail, "5@mega.nz")
        XCTAssertEqual(source.currentUserHandle, 5)
        XCTAssertFalse(source.isGuest)
    }
    
    func testAccountDetails_fetchAccountDetailsNotif_shouldUpdate() {
        let source = CurrentUserSource(sdk: MockSdk())
        let accountDetails = AccountDetailsEntity.build(proLevel: .proI)
        NotificationCenter.default.post(name: .accountDidFinishFetchAccountDetails, object: accountDetails)
        let exp = expectation(description: "accountDetails from notif")
        _ = XCTWaiter.wait(for: [exp], timeout: 0.01)
        XCTAssertEqual(accountDetails, source.accountDetails)
    }
    
    func testAccountDetails_fetchAccountDetails_shouldUpdate() {
        let source = CurrentUserSource(sdk: MockSdk())
        let accountDetails = AccountDetailsEntity.build(proLevel: .proI)
        source.setAccountDetails(accountDetails)
        XCTAssertEqual(accountDetails, source.accountDetails)
    }
}

@Suite("CurrentUserSource Tests")
struct CurrentUserSourceTestsSuite {
    @Suite("isPayWalled")
    struct PaywalledSuite {
        @Test("when storage state event number is paywall it should return true",
              arguments: [
                (StorageState.green, false),
                (StorageState.orange, false),
                (StorageState.red, false),
                (StorageState.change, false),
                (StorageState.paywall, true)]
        )
        func notificationStorageEvent(storageState: StorageState, expectedIsPaywalled: Bool) async throws {
            let notificationCenter = NotificationCenter()
            let source = CurrentUserSource(
                sdk: MockSdk(), notificationCenter: notificationCenter)
            
            notificationCenter.post(
                name: .storageEventDidChange, object: nil,
                userInfo: [NotificationUserInfoKey.storageEventState: NSNumber(value: storageState.rawValue)])
            
            try await Task.sleep(nanoseconds: 10_000_000)
            
            #expect(source.isPaywalled == expectedIsPaywalled)
        }
    }
}
