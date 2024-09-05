import MEGADomain
import MEGADomainMock
import MEGASwift
import XCTest

final class MyAccountHallUseCaseTests: XCTestCase {
    
    func testContactRequestsCount_onViewAppear_shouldBeEqual() async {
        let contactsRequestsExpectedCount = 1
        let sut = MyAccountHallUseCase(repository: MockAccountRepository(contactsRequestsCount: contactsRequestsExpectedCount))
        let contactsCount = await sut.incomingContactsRequestsCount()
        
        XCTAssertEqual(contactsCount, contactsRequestsExpectedCount)
    }
    
    func testUnseenUserAlertsCount_onViewAppear_shouldBeEqual() async {
        let unSeenUserAlertsExpectedCount: UInt = 2
        let sut = MyAccountHallUseCase(repository: MockAccountRepository(unseenUserAlertsCount: unSeenUserAlertsExpectedCount))
        let unSeenUserAlertsCount = await sut.relevantUnseenUserAlertsCount()
        
        XCTAssertEqual(unSeenUserAlertsCount, unSeenUserAlertsExpectedCount)
    }
    
    func test_isMasterBusinessAccount_shouldBeTrue() {
        let sut = MyAccountHallUseCase(repository: MockAccountRepository(isMasterBusinessAccount: true))
        XCTAssertTrue(sut.isMasterBusinessAccount)
    }
    
    func test_isMasterBusinessAccount_shouldBeFalse() {
        let sut = MyAccountHallUseCase(repository: MockAccountRepository(isMasterBusinessAccount: false))
        XCTAssertFalse(sut.isMasterBusinessAccount)
    }
    
    func testIsAchievementsEnabled_shouldBeTrue() {
        let sut = MyAccountHallUseCase(repository: MockAccountRepository(isAchievementsEnabled: true))
        XCTAssertTrue(sut.isAchievementsEnabled)
    }
    
    func testIsAchievementsEnabled_shouldBeFalse() {
        let sut = MyAccountHallUseCase(repository: MockAccountRepository(isAchievementsEnabled: false))
        XCTAssertFalse(sut.isAchievementsEnabled)
    }
    
    func testCurrentAccountDetails_shouldReturnCurrentAccountDetails() {
        let accountDetails = AccountDetailsEntity.random
        let sut = MyAccountHallUseCase(repository: MockAccountRepository(currentAccountDetails: accountDetails))
        
        XCTAssertEqual(sut.currentAccountDetails, accountDetails)
    }
    
    func testRefreshCurrentAccountDetails_whenSuccess_shouldReturnAccountDetails() async throws {
        let accountDetails = AccountDetailsEntity.random
        let sut = MyAccountHallUseCase(repository: MockAccountRepository(accountDetailsResult: .success(accountDetails)))
        
        let currentAccountDetails = try await sut.refreshCurrentAccountDetails()
        XCTAssertEqual(currentAccountDetails, accountDetails)
    }
    
    func testRefreshCurrentAccountDetails_whenFails_shouldThrowGenericError() async {
        let sut = MyAccountHallUseCase(repository: MockAccountRepository(accountDetailsResult: .failure(.generic)))
        
        await XCTAsyncAssertThrowsError(try await sut.refreshCurrentAccountDetails()) { errorThrown in
            XCTAssertEqual(errorThrown as? AccountDetailsErrorEntity, .generic)
        }
    }
    
    func testOnAccountRequestFinish_successRequest_shouldReturnSuccessRequest() async {
        let sut = MyAccountHallUseCase(
            repository: makeMockAccountRepository(accountRequestUpdate: .success(AccountRequestEntity(type: .accountDetails, file: nil, userAttribute: nil, email: nil)))
        )
        var iterator = sut.onAccountRequestFinish.makeAsyncIterator()
        
        let result = await iterator.next()
        await XCTAsyncAssertNoThrow(try result?.get())
    }
    
    func testOnAccountRequestFinish_failedRequest_shouldReturnFailedRequest() async {
        let sut = MyAccountHallUseCase(
            repository: makeMockAccountRepository(accountRequestUpdate: .failure(AccountDetailsErrorEntity.generic))
        )
        var iterator = sut.onAccountRequestFinish.makeAsyncIterator()
        
        let result = await iterator.next()
        XCTAssertThrowsError(try result?.get())
    }
    
    func testOnUserAlertsUpdates_onUpdate_shouldReturnUserAlerts() async {
        let updates = [UserAlertEntity.random, UserAlertEntity.random]
        let sut = MyAccountHallUseCase(
            repository: makeMockAccountRepository(userAlertsUpdates: updates)
        )
        var iterator = sut.onUserAlertsUpdates.makeAsyncIterator()
        
        let result = await iterator.next()
        XCTAssertEqual(result, updates)
    }
    
    func testOnContactRequestsUpdates_onUpdate_shouldReturnContactRequests() async {
        let updates = [ContactRequestEntity.random, ContactRequestEntity.random]
        let sut = MyAccountHallUseCase(
            repository: makeMockAccountRepository(contactRequestsUpdates: updates)
        )
        var iterator = sut.onContactRequestsUpdates.makeAsyncIterator()
        
        let result = await iterator.next()
        XCTAssertEqual(result, updates)
    }
    
    // MARK: - Helper
    private func makeMockAccountRepository(
        accountRequestUpdate: Result<AccountRequestEntity, any Error> = .failure(AccountErrorEntity.generic),
        userAlertsUpdates: [UserAlertEntity] = [],
        contactRequestsUpdates: [ContactRequestEntity] = []
    ) -> MockAccountRepository {

        MockAccountRepository(
            onAccountRequestFinishUpdate: SingleItemAsyncSequence(item: accountRequestUpdate).eraseToAnyAsyncSequence(),
            onUserAlertsUpdates: SingleItemAsyncSequence(item: userAlertsUpdates).eraseToAnyAsyncSequence(),
            onContactRequestsUpdates: SingleItemAsyncSequence(item: contactRequestsUpdates).eraseToAnyAsyncSequence()
        )
    }
}
