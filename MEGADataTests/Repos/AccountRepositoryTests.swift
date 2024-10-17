import MEGADomain
import MEGADomainMock
import MEGASDKRepo
import MEGASDKRepoMock
import MEGASwift
import XCTest

@testable import MEGA

final class AccountRepositoryTests: XCTestCase {
    private let urlPath = "https://mega.nz"
    
    func testCurrentUserHandle() {
        let expectedHandle = HandleEntity.random()
        
        let (sut, _) = makeSUT(user: MockUser(handle: expectedHandle))
        
        XCTAssertEqual(sut.currentUserHandle, expectedHandle)
    }
    
    func testCurrentUser() async {
        let expectedUser = MockUser(handle: .random())
        
        let (sut, _) = makeSUT(user: expectedUser)
        
        let currentUser = await sut.currentUser()
        XCTAssertEqual(currentUser, expectedUser.toUserEntity())
    }
    
    func testIsGuest() {
        func assert(
            whenUserEmail email: String,
            isGuestShouldBe expectedIsGuest: Bool,
            line: UInt = #line
        ) {
            let (sut, _) = makeSUT(user: MockUser(email: email))
            
            XCTAssertEqual(sut.isGuest, expectedIsGuest, line: line)
        }
        
        assert(whenUserEmail: "", isGuestShouldBe: true)
        assert(whenUserEmail: "any-email@mega.com", isGuestShouldBe: false)
    }
    
    func testIsLoggedIn() {
        let (sut, _) = makeSUT(isLoggedIn: 1)
        XCTAssertTrue(sut.isLoggedIn())
        let (sut2, _) = makeSUT(isLoggedIn: 0)
        XCTAssertFalse(sut2.isLoggedIn())
    }
    
    func testIsMasterBusinessAccount() {
        let (sut, _) = makeSUT(isMasterBusinessAccount: true)
        XCTAssertTrue(sut.isMasterBusinessAccount)
        let (sut2, _) = makeSUT()
        XCTAssertFalse(sut2.isMasterBusinessAccount)
    }
    
    func testIsAchievementsEnabled() {
        let (sut, _) = makeSUT(isAchievementsEnabled: true)
        XCTAssertTrue(sut.isAchievementsEnabled)
        let (sut2, _) = makeSUT()
        XCTAssertFalse(sut2.isAchievementsEnabled)
    }
    
    func testIsNewAccount() {
        let (sut, _) = makeSUT(isNewAccount: true)
        XCTAssertTrue(sut.isNewAccount)
        let (sut2, _) = makeSUT()
        XCTAssertFalse(sut2.isNewAccount)
    }
    
    func testCurrentProPlan_noExistingProPlans_shouldReturnNil() {
        let accountDetails = AccountDetailsEntity.build(plans: [])
        let (sut, _) = makeSUT(accountDetailsEntity: accountDetails)
        
        XCTAssertNil(sut.currentProPlan)
    }
    
    func testCurrentProPlan_hasAccountProPlanOnList_shouldReturnProPlan() {
        let accountProPlan = AccountPlanEntity(isProPlan: true)
        let accountDetails = AccountDetailsEntity.build(plans: [accountProPlan])
        let (sut, _) = makeSUT(accountDetailsEntity: accountDetails)
        
        XCTAssertEqual(sut.currentProPlan, accountProPlan)
    }
    
    func testCurrentSubscription_noExistingSubscription_shouldReturnNil() {
        let accountDetails = AccountDetailsEntity.build(
            subscriptions: [],
            plans: [AccountPlanEntity(isProPlan: false, subscriptionId: nil)]
        )
        
        let (sut, _) = makeSUT(accountDetailsEntity: accountDetails)
        
        XCTAssertNil(sut.currentSubscription())
    }
    
    func testCurrentSubscription_hasMatchingSubscription_shouldReturnSubscription() {
        let subscriptionId = "123ABC"
        let expectedSubscription = AccountSubscriptionEntity(id: subscriptionId)
        let accountDetails = AccountDetailsEntity.build(
            subscriptions: [
                expectedSubscription
            ],
            plans: [
                AccountPlanEntity(isProPlan: true, subscriptionId: subscriptionId),
                AccountPlanEntity(isProPlan: false, subscriptionId: nil)
            ]
        )
        
        let (sut, _) = makeSUT(accountDetailsEntity: accountDetails)
        
        XCTAssertEqual(sut.currentSubscription(), expectedSubscription)
    }
    
    func testCurrentSubscription_hasNoMatchingSubscription_shouldReturnNil() {
        let accountDetails = AccountDetailsEntity.build(
            subscriptions: [
                AccountSubscriptionEntity(id: "123ABC")
            ],
            plans: [
                AccountPlanEntity(isProPlan: true, subscriptionId: "456DEF"),
                AccountPlanEntity(isProPlan: false, subscriptionId: nil)
            ]
        )
        
        let (sut, _) = makeSUT(accountDetailsEntity: accountDetails)
        
        XCTAssertNil(sut.currentSubscription())
    }
    
    func testMultipleProSubscriptions_whenUserHasMultipleBilledSubscriptions_shouldReturnTrue() {
        let accountDetails = AccountDetailsEntity.build(
            subscriptions: [
                AccountSubscriptionEntity(id: "123ABC", accountType: .lite),
                AccountSubscriptionEntity(id: "456DEF", accountType: .proI)
            ],
            plans: [
                AccountPlanEntity(isProPlan: true, subscriptionId: "456DEF")
            ]
        )
        
        let (sut, _) = makeSUT(accountDetailsEntity: accountDetails)
        
        XCTAssertTrue(sut.hasMultipleBilledProPlans())
    }
    
    func testMultipleProSubscriptions_whenUserHasBilledAndFeatureSubscriptions_shouldReturnFalse() {
        let accountDetails = AccountDetailsEntity.build(
            subscriptions: [
                AccountSubscriptionEntity(id: "123ABC", accountType: .feature),
                AccountSubscriptionEntity(id: "456DEF", accountType: .proI)
            ],
            plans: [
                AccountPlanEntity(isProPlan: true, subscriptionId: "456DEF")
            ]
        )
        
        let (sut, _) = makeSUT(accountDetailsEntity: accountDetails)
        
        XCTAssertFalse(sut.hasMultipleBilledProPlans())
    }
    
    func testAccountCreationDate_whenNil_shouldReturnNil() {
        let (sut, _) = makeSUT()
        XCTAssertNil(sut.accountCreationDate)
    }
    
    func testAccountCreationDate_whenNotNil_shouldReturnValue() {
        let stubbedDate = Date()
        let (sut, _) = makeSUT(accountCreationDate: stubbedDate)
        XCTAssertEqual(sut.accountCreationDate, stubbedDate)
    }
    
    func testContacts_shouldMapSdkContacts() {
        let userStubOne = MockUser()
        let userStubTwo = MockUser()
        let (sut, _) = makeSUT(myContacts: MockUserList(users: [userStubOne, userStubTwo]))
        
        XCTAssertEqual(sut.contacts(), [userStubOne.toUserEntity(), userStubTwo.toUserEntity()])
    }
    
    func testBandwidthOverquotaDelay_returnBandwidth() {
        let expectedBandwidth: Int64 = 100
        let (sut, _) = makeSUT(bandwidthOverquotaDelay: expectedBandwidth)
        XCTAssertEqual(sut.bandwidthOverquotaDelay, expectedBandwidth)
    }
    
    func testIncomingContactsRequestCount() {
        func assert(
            whenContactRequestCount expectedCount: Int,
            line: UInt = #line
        ) {
            let (sut, _) = makeSUT(incomingContactRequestList: MockContactRequestList(
                    contactRequests: Array(repeating: MockContactRequest(), count: expectedCount)
                )
            )
            
            XCTAssertEqual(sut.incomingContactsRequestsCount(), expectedCount, line: line)
        }
        
        assert(whenContactRequestCount: 0)
        assert(whenContactRequestCount: 1)
        assert(whenContactRequestCount: 5)
        assert(whenContactRequestCount: 10)
    }
    
    func testRelevantUnseenUserAlertsCount() {
        func assert(
            whenAlertsInSDK alerts: [MockUserAlert],
            relevantUnseenUserAlertsCount expectedCount: UInt,
            line: UInt = #line
        ) {
            let (sut, _) = makeSUT(userAlertList: MockUserAlertList(alerts: alerts))
            
            XCTAssertEqual(sut.relevantUnseenUserAlertsCount(), expectedCount, line: line)
        }
        
        assert(whenAlertsInSDK: [], relevantUnseenUserAlertsCount: 0)
        
        assert(
            whenAlertsInSDK: [
                MockUserAlert(isSeen: true, isRelevant: true),
                MockUserAlert(isSeen: false, isRelevant: false),
                MockUserAlert(isSeen: true, isRelevant: true)
            ],
            relevantUnseenUserAlertsCount: 0
        )
        
        assert(
            whenAlertsInSDK: [
                MockUserAlert(isSeen: false, isRelevant: true),
                MockUserAlert(isSeen: false, isRelevant: true),
                MockUserAlert(isSeen: false, isRelevant: true)
            ],
            relevantUnseenUserAlertsCount: 3
        )
        
        assert(
            whenAlertsInSDK: [
                MockUserAlert(isSeen: true, isRelevant: true),
                MockUserAlert(isSeen: false, isRelevant: true),
                MockUserAlert(isSeen: false, isRelevant: false),
                MockUserAlert(isSeen: false, isRelevant: true),
                MockUserAlert(isSeen: true, isRelevant: true),
                MockUserAlert(isSeen: false, isRelevant: true)
            ],
            relevantUnseenUserAlertsCount: 3
        )
    }
    
    func testTotalNodesCount() {
        func assert(
            whenNodesCount expectedCount: Int,
            line: UInt = #line
        ) {
            let (sut, _) = makeSUT(nodes: Array(repeating: MockNode(handle: .invalidHandle), count: expectedCount))
            
            XCTAssertEqual(sut.totalNodesCount(), UInt64(expectedCount), line: line)
        }
        
        assert(whenNodesCount: 0)
        assert(whenNodesCount: 1)
        assert(whenNodesCount: 5)
        assert(whenNodesCount: 10)
    }
    
    func testCurrentAccountDetails_shouldReturnCurrentAccountDetails() async {
        let expectedAccountDetails = randomAccountDetails()
        let (sut, _) = makeSUT(accountDetails: expectedAccountDetails)
        
        XCTAssertEqual(sut.currentAccountDetails, expectedAccountDetails.toAccountDetailsEntity())
    }
    
    func testRefreshCurrentAccountDetails_whenFails_shouldThrowGenericError() async {
        let expectedError = MockError.failingError
        let (sut, _) = makeSUT(accountDetailsClosure: { sdk, delegate in
                delegate.onRequestFinish?(sdk, request: MockRequest(handle: 1), error: expectedError)
            }
        )
        
        await XCTAsyncAssertThrowsError(try await sut.refreshCurrentAccountDetails()) { errorThrown in
            XCTAssertEqual(errorThrown as? AccountDetailsErrorEntity, .generic)
        }
    }
    
    func testRefreshCurrentAccountDetails_whenSuccess_shouldReturnAccountDetails() async throws {
        let expectedAccountDetails = randomAccountDetails()
        let (sut, _) = makeSUT(accountDetailsClosure: { sdk, delegate in
                delegate.onRequestFinish?(
                    sdk,
                    request: MockRequest(handle: 1, accountDetails: expectedAccountDetails),
                    error: MockError(errorType: .apiOk))
            }
        )
        
        let accountDetails = try await sut.refreshCurrentAccountDetails()
        XCTAssertEqual(accountDetails, expectedAccountDetails.toAccountDetailsEntity())
        XCTAssertEqual(accountDetails, sut.currentAccountDetails)
    }
    
    func testUpgradeSecurity_whenApiOk_shouldNotThrow() async {
        let apiOk = MockError(errorType: .apiOk)
        let (sut, _) = makeSUT(upgradeSecurityClosure: { sdk, delegate in
                delegate.onRequestFinish?(sdk, request: MockRequest(handle: 1), error: apiOk)
            }
        )
        
        await XCTAsyncAssertNoThrow(try await sut.upgradeSecurity())
    }
    
    func testUpgradeSecurity_whenFails_shouldThrowGenericError() async {
        let expectedError = MockError.failingError
        let (sut, _) = makeSUT(upgradeSecurityClosure: { sdk, delegate in
                delegate.onRequestFinish?(sdk, request: MockRequest(handle: 1), error: expectedError)
            }
        )
        
        await XCTAsyncAssertThrowsError(try await sut.upgradeSecurity()) { errorThrown in
            XCTAssertEqual(errorThrown as? AccountErrorEntity, .generic)
        }
    }
    
    func testOnAccountRequestFinish_successRequest_shouldYieldElement() async {
        let (sut, _) = makeSUT(
            accountRequestUpdate: .success(AccountRequestEntity(type: .accountDetails, file: nil, userAttribute: nil, email: nil))
        )
        var iterator = sut.onAccountRequestFinish.makeAsyncIterator()
        
        let result = await iterator.next()
        await XCTAsyncAssertNoThrow(try result?.get())
    }
    
    func testOnAccountRequestFinish_failedRequest_shouldYieldElement() async {
        let (sut, _) = makeSUT(
            accountRequestUpdate: .failure(MockError.failingError)
        )
        var iterator = sut.onAccountRequestFinish.makeAsyncIterator()
        
        let result = await iterator.next()
        XCTAssertThrowsError(try result?.get())
    }
    
    func testOnUserAlertsUpdates_onUpdate_shouldYieldElements() async {
        let updates = [UserAlertEntity.random, UserAlertEntity.random]
        let (sut, _) = makeSUT(userAlertsUpdates: updates)
        var iterator = sut.onUserAlertsUpdates.makeAsyncIterator()
        
        let result = await iterator.next()
        XCTAssertEqual(result, updates)
    }
    
    func testOnContactRequestsUpdate_onUpdate_shouldYieldElements() async {
        let updates = [ContactRequestEntity.random, ContactRequestEntity.random]
        
        let (sut, _) = makeSUT(contactRequestsUpdates: updates)
        var iterator = sut.onContactRequestsUpdates.makeAsyncIterator()
        
        let result = await iterator.next()
        XCTAssertEqual(result, updates)
    }
    
    func testGetMiscFlag_whenApiOk_shouldNotThrow() async {
        let (sut, _) = makeSUT(requestResult: .success(MockRequest(handle: 1)))

        await XCTAsyncAssertNoThrow(try await sut.getMiscFlags())
    }
    
    func testGetMiscFlag_whenFail_shouldThrowGenericError() async {
        let (sut, _) = makeSUT(requestResult: .failure(MockError.failingError))
        
        await XCTAsyncAssertThrowsError(try await sut.getMiscFlags()) { errorThrown in
            XCTAssertEqual(errorThrown as? AccountErrorEntity, .generic)
        }
    }
    
    func testSessionTransferURL_whenApiOk_shouldReturnURL() async throws {
        let expectedURL = try XCTUnwrap(URL(string: urlPath))
        let (sut, _) = makeSUT(requestResult: .success(MockRequest(handle: 1, link: urlPath)))
        
        let urlResult = try await sut.sessionTransferURL(path: urlPath)
        
        XCTAssertEqual(urlResult, expectedURL)
    }
    
    func testSessionTransferURL_whenFail_shouldThrowGenericError() async throws {
        let (sut, _) = makeSUT(requestResult: .failure(MockError.failingError))
        
        await XCTAsyncAssertThrowsError(try await sut.sessionTransferURL(path: urlPath)) { errorThrown in
            XCTAssertEqual(errorThrown as? AccountErrorEntity, .generic)
        }
    }
    
    func testSessionTransferURL_whenApiOkButInvalidURLLink_shouldThrowGenericError() async throws {
        let (sut, _) = makeSUT(requestResult: .success(MockRequest(handle: 1, link: nil)))
        
        await XCTAsyncAssertThrowsError(try await sut.sessionTransferURL(path: urlPath)) { errorThrown in
            XCTAssertEqual(errorThrown as? AccountErrorEntity, .generic)
        }
    }
    
    func testRootStorageUsed_withValidHandle_shouldReturnCorrectStorage() {
        let rootNodeHandle: UInt64 = 1
        let expectedSize: Int64 = 100

        let (sut, _) = makeSUT(
            rootNodeHandle: rootNodeHandle,
            nodeSizes: [rootNodeHandle: expectedSize]
        )

        let usedStorage = sut.rootStorageUsed()
        XCTAssertEqual(usedStorage, expectedSize)
    }
    
    func testRubbishBinStorageUsed_withValidHandle_shouldReturnCorrectStorage() {
        let rubbishNodeHandle: UInt64 = 2
        let expectedSize: Int64 = 50
        
        let (sut, _) = makeSUT(
            rubbishNodeHandle: rubbishNodeHandle,
            nodeSizes: [rubbishNodeHandle: expectedSize]
        )
        
        let usedStorage = sut.rubbishBinStorageUsed()
        XCTAssertEqual(usedStorage, expectedSize)
    }
    
    func testIncomingSharesStorageUsed_withValidNodes_shouldReturnCorrectStorage() {
        let incomingNode1Handle: UInt64 = 1
        let incomingNode1Size: Int64 = 10
        let incomingNode2Handle: UInt64 = 2
        let incomingNode2Size: Int64 = 20
        let (sut, _) = makeSUT(
            nodeSizes: [
                incomingNode1Handle: incomingNode1Size,
                incomingNode2Handle: incomingNode2Size
            ],
            incomingNodes: [
                MockNode(handle: incomingNode1Handle),
                MockNode(handle: incomingNode2Handle)
            ]
        )
        
        let usedStorage = sut.incomingSharesStorageUsed()
        XCTAssertEqual(usedStorage, incomingNode1Size + incomingNode2Size)
    }
    
    func testBackupStorageUsed_withValidNode_shouldReturnCorrectStorage() async throws {
        let backupNodeHandle: UInt64 = 4
        let expectedSize: Int64 = 25
        
        let (sut, _) = makeSUT(
            nodes: [MockNode(handle: backupNodeHandle)],
            backupRootNodeHandle: backupNodeHandle,
            currentSize: expectedSize
        )
        
        let usedStorage = try await sut.backupStorageUsed()
        XCTAssertEqual(usedStorage, expectedSize)
    }
    
    func testOnStorageStatusUpdates_whenReceivingUpdates_shouldEmitCorrectValues() async throws {
        let expectedStatusUpdates: [StorageStatusEntity] = [.almostFull, .full, .pendingChange, .paywall]
        let asyncStream = makeAsyncStream(for: expectedStatusUpdates)
        let (sut, _) = makeSUT(onStorageStatusUpdates: asyncStream)
        let expectation = XCTestExpectation(description: "Wait for all status updates")
        var receivedStatusUpdates: [StorageStatusEntity] = []
        
        Task {
            for await status in sut.onStorageStatusUpdates {
                receivedStatusUpdates.append(status)
                if receivedStatusUpdates.count == expectedStatusUpdates.count {
                    expectation.fulfill()
                }
            }
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedStatusUpdates, expectedStatusUpdates)
    }

    func testRefreshCurrentStorageState_whenFull_shouldReturnFull() async throws {
        try await assertRefreshStorageState(expectedState: .full)
    }

    func testRefreshCurrentStorageState_whenAlmostFull_shouldReturnAlmostFull() async throws {
        try await assertRefreshStorageState(expectedState: .almostFull)
    }

    func testRefreshCurrentStorageState_whenNoStorageProblems_shouldReturnNoStorageProblems() async throws {
        try await assertRefreshStorageState(expectedState: .noStorageProblems)
    }
    
    func testRefreshCurrentStorageState_whenPendingChange_shouldReturnPendingChange() async throws {
        try await assertRefreshStorageState(expectedState: .pendingChange)
    }

    func testRefreshCurrentStorageState_whenPaywall_shouldReturnPaywall() async throws {
        try await assertRefreshStorageState(expectedState: .paywall)
    }
    
    func testCurrentStorageStatus_whenNoStorageStatus_shouldReturnNoStorageProblems() {
        let (sut, _) = makeSUT()
        
        XCTAssertEqual(sut.currentStorageStatus, .noStorageProblems)
        XCTAssertTrue(sut.shouldRefreshStorageStatus)
    }
    
    func testCurrentStorageStatus_whenStorageStatusIsSet_shouldReturnCorrectValue() {
        let expectedStorageStatus: StorageStatusEntity = .almostFull
        let (sut, _) = makeSUT(storageStatus: expectedStorageStatus)
        
        XCTAssertEqual(sut.currentStorageStatus, expectedStorageStatus)
    }
    
    func testIsUnlimitedStorageAccount_whenProFlexiAccount_shouldReturnTrue() {
        let accountDetails = AccountDetailsEntity.build(proLevel: .proFlexi)
        let (sut, _) = makeSUT(accountDetailsEntity: accountDetails)

        XCTAssertTrue(sut.isUnlimitedStorageAccount)
    }

    func testIsUnlimitedStorageAccount_whenBusinessAccount_shouldReturnTrue() {
        let accountDetails = AccountDetailsEntity.build(proLevel: .business)
        let (sut, _) = makeSUT(accountDetailsEntity: accountDetails)

        XCTAssertTrue(sut.isUnlimitedStorageAccount)
    }

    func testIsUnlimitedStorageAccount_whenFreeAccount_shouldReturnFalse() {
        let accountDetails = AccountDetailsEntity.build(proLevel: .free)
        let (sut, _) = makeSUT(accountDetailsEntity: accountDetails)

        XCTAssertFalse(sut.isUnlimitedStorageAccount)
    }

    func testIsUnlimitedStorageAccount_whenProAccount_shouldReturnFalse() {
        let accountDetails = AccountDetailsEntity.build(proLevel: .proI)
        let (sut, _) = makeSUT(accountDetailsEntity: accountDetails)

        XCTAssertFalse(sut.isUnlimitedStorageAccount)
    }

    func testIsUnlimitedStorageAccount_whenNoAccountDetails_shouldReturnFalse() {
        let (sut, _) = makeSUT()

        XCTAssertFalse(sut.isUnlimitedStorageAccount)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        nodes: [MockNode] = [],
        user: MockUser? = nil,
        isLoggedIn: Int = 0,
        isMasterBusinessAccount: Bool = false,
        isAchievementsEnabled: Bool = false,
        isNewAccount: Bool = false,
        accountCreationDate: Date? = nil,
        myContacts: MockUserList = MockUserList(users: []),
        bandwidthOverquotaDelay: Int64 = 0,
        incomingContactRequestList: MockContactRequestList = MockContactRequestList(contactRequests: []),
        userAlertList: MockUserAlertList = MockUserAlertList(alerts: []),
        rootNodeHandle: UInt64 = 0,
        rubbishNodeHandle: UInt64 = 0,
        myChatFilesNodeHandle: UInt64 = 0,
        backupRootNodeHandle: UInt64 = 0,
        nodeSizes: [UInt64: Int64] = [:],
        incomingNodes: [MockNode] = [],
        currentSize: Int64 = 0,
        shouldRefreshAccountDetails: Bool = false,
        accountDetails: MockMEGAAccountDetails? = nil,
        accountDetailsEntity: AccountDetailsEntity? = nil,
        upgradeSecurityClosure: @escaping (MEGASdk, any MEGARequestDelegate) -> Void = { _, _ in },
        accountDetailsClosure: @escaping (MEGASdk, any MEGARequestDelegate) -> Void = { _, _ in },
        requestResult: MockSdkRequestResult = .failure(MockError.failingError),
        accountRequestUpdate: Result<AccountRequestEntity, any Error> = .failure(MockError.failingError),
        userAlertsUpdates: [UserAlertEntity] = [],
        contactRequestsUpdates: [ContactRequestEntity] = [],
        onStorageStatusUpdates: AnyAsyncSequence<StorageStatusEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        storageStatus: StorageStatusEntity? = nil
    ) -> (AccountRepository, MockSdk) {
        let incomingNodes = MockNodeList(nodes: incomingNodes)
        let myChatFilesRootNodeAccess = nodeAccess(for: myChatFilesNodeHandle)
        let backupsRootNodeAccess = nodeAccess(for: backupRootNodeHandle)
        
        let mockSdk = MockSdk(
            nodes: nodes,
            incomingNodes: incomingNodes,
            myContacts: myContacts,
            myUser: user,
            isLoggedIn: isLoggedIn,
            isMasterBusinessAccount: isMasterBusinessAccount,
            isAchievementsEnabled: isAchievementsEnabled,
            isNewAccount: isNewAccount,
            bandwidthOverquotaDelay: bandwidthOverquotaDelay,
            megaRootNode: rootNodeHandle > 0 ? MockNode(handle: rootNodeHandle): nil,
            rubbishBinNode: rubbishNodeHandle > 0 ? MockNode(handle: rubbishNodeHandle): nil,
            incomingContactRequestList: incomingContactRequestList,
            userAlertList: userAlertList,
            upgradeSecurity: upgradeSecurityClosure,
            accountDetails: accountDetailsClosure,
            requestResult: requestResult,
            accountCreationDate: accountCreationDate,
            nodeSizes: nodeSizes,
            folderInfo: MockFolderInfo(currentSize: currentSize),
            storageState: storageStatus?.toStorageState()
        )
        
        let currentUserSource = CurrentUserSource(sdk: mockSdk)
        
        if let accountDetailsEntity {
            currentUserSource.setAccountDetails(accountDetailsEntity)
        } else {
            currentUserSource.setAccountDetails(
                (accountDetails ?? defaultAccountDetails(type: .free, nodeSizes: nodeSizes))
                    .toAccountDetailsEntity()
            )
        }
        
        if let storageStatus {
            currentUserSource.setStorageStatus(storageStatus)
        }
        
        currentUserSource.setShouldRefreshAccountDetails(shouldRefreshAccountDetails)
        
        let accountUpdatesProvider = MockAccountUpdatesProvider(
            onAccountRequestFinish: SingleItemAsyncSequence(item: accountRequestUpdate).eraseToAnyAsyncSequence(),
            onUserAlertsUpdates: SingleItemAsyncSequence(item: userAlertsUpdates).eraseToAnyAsyncSequence(),
            onContactRequestsUpdates: SingleItemAsyncSequence(item: contactRequestsUpdates).eraseToAnyAsyncSequence(),
            onStorageStatusUpdates: onStorageStatusUpdates
        )

        return (AccountRepository(
            sdk: mockSdk,
            currentUserSource: currentUserSource,
            myChatFilesFolderNodeAccess: myChatFilesRootNodeAccess,
            backupsRootFolderNodeAccess: backupsRootNodeAccess,
            accountUpdatesProvider: accountUpdatesProvider
        ), mockSdk)
    }
    
    private func nodeAccess(for nodeHandle: UInt64) -> any NodeAccessProtocol {
        MockNodeAccess(
           result: nodeHandle > 0 ?
               .success(MockNode(handle: nodeHandle)) :
               .failure(GenericErrorEntity())
       )
    }
    
    private func defaultAccountDetails(
        type: AccountTypeEntity,
        nodeSizes: [UInt64: Int64]
    ) -> MockMEGAAccountDetails {
        MockMEGAAccountDetails(
            type: type.toMEGAAccountType(),
            nodeSizes: nodeSizes
        )
    }
    
    private func randomAccountDetails() -> MockMEGAAccountDetails {
        MockMEGAAccountDetails(type: MEGAAccountType(rawValue: .random(in: 0...4)) ?? .free)
    }
    
    private func makeAsyncStream(for updates: [StorageStatusEntity]) -> AnyAsyncSequence<StorageStatusEntity> {
        AsyncStream { continuation in
            for update in updates {
                continuation.yield(update)
            }
            continuation.finish()
        }.eraseToAnyAsyncSequence()
    }
    
    private func assertRefreshStorageState(
        expectedState: StorageStatusEntity,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let (sut, _) = makeSUT(storageStatus: expectedState)
        
        let result = try await sut.refreshCurrentStorageState()
        
        XCTAssertEqual(result, expectedState, file: file, line: line)
    }
}
