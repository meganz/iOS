import Combine
import MEGADomain
import MEGADomainMock
import MEGASDKRepo
import MEGASDKRepoMock
import MEGASwift
import XCTest

@testable import MEGA

final class AccountRepositoryTests: XCTestCase {
    private let urlPath = "https://mega.nz"
    private var subscriptions = Set<AnyCancellable>()
    
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
    
    func testRequestResultPublisher_onRequestFinish_whenApiOk_sendsSuccessResult() {
        let apiOk = MockError(errorType: .apiOk)
        let (sut, mockSdk) = makeSUT()
        
        let exp = expectation(description: "Should receive success AccountRequestEntity")
        let megaRequest = MEGARequest()
        sut.requestResultPublisher
            .sink { request in
                switch request {
                case .success(let result):
                    XCTAssertEqual(result, megaRequest.toAccountRequestEntity())
                case .failure:
                    XCTFail("Request error is not expected.")
                }
                exp.fulfill()
            }.store(in: &subscriptions)
        sut.onRequestFinish(mockSdk, request: megaRequest, error: apiOk)
        wait(for: [exp], timeout: 1)
    }
    
    func testRequestResultPublisher_onRequestFinish_withError_sendsError() {
        let apiError = MockError.failingError
        let (sut, mockSdk) = makeSUT()
        
        let exp = expectation(description: "Should receive success AccountRequestEntity")
        sut.requestResultPublisher
            .sink { request in
                switch request {
                case .success:
                    XCTFail("Expecting an error but got a success.")
                case .failure(let error):
                    guard let err = error as? MEGAError else {
                        XCTFail("Error can't cast as MEGAError")
                        return
                    }
                    XCTAssertEqual(err.type, apiError.type)
                }
                exp.fulfill()
            }.store(in: &subscriptions)
        sut.onRequestFinish(mockSdk, request: MEGARequest(), error: apiError)
        wait(for: [exp], timeout: 1)
    }
    
    func testContactRequestPublisher_onContactRequestsUpdate_sendsContactRequestList() {
        let (sut, mockSdk) = makeSUT()
        
        let exp = expectation(description: "Should receive ContactRequestEntity list")
        let expectedContactRequest = ContactRequestEntity.random
        sut.contactRequestPublisher
            .sink { list in
                XCTAssertEqual(list, [expectedContactRequest])
                exp.fulfill()
            }.store(in: &subscriptions)
        
        let mockContactRequestList = MockContactRequestList(contactRequests: [MockContactRequest(handle: expectedContactRequest.handle)])
        sut.onContactRequestsUpdate(mockSdk, contactRequestList: mockContactRequestList)
        wait(for: [exp], timeout: 1)
    }
    
    func testUserAlertPublisher_onUserAlertsUpdate_sendsUserAlertList() {
        let (sut, mockSdk) = makeSUT()
        
        let exp = expectation(description: "Should receive UserAlertEntity list")
        let expectedUserAlert = UserAlertEntity.random
        sut.userAlertUpdatePublisher
            .sink { list in
                XCTAssertEqual(list, [expectedUserAlert])
                exp.fulfill()
            }.store(in: &subscriptions)
        
        let mockUserAlertList = MockUserAlertList(alerts: [MockUserAlert(identifier: expectedUserAlert.identifier)])
        sut.onUserAlertsUpdate(mockSdk, userAlertList: mockUserAlertList)
        wait(for: [exp], timeout: 1)
    }
    
    func testOnRequestResultFinish_addDelegate_delegateShouldExist() async {
        let (sut, mockSdk) = makeSUT()
        await sut.registerMEGARequestDelegate()
        
        XCTAssertTrue(mockSdk.hasRequestDelegate)
    }
    
    func testOnRequestResultFinish_removeDelegate_delegateShouldNotExist() async {
        let (sut, mockSdk) = makeSUT()
        
        mockSdk.hasRequestDelegate = true
        
        await sut.deRegisterMEGARequestDelegate()
        
        XCTAssertFalse(mockSdk.hasRequestDelegate)
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
        accountDetails: MockMEGAAccountDetails? = nil,
        upgradeSecurityClosure: @escaping (MEGASdk, any MEGARequestDelegate) -> Void = { _, _ in },
        accountDetailsClosure: @escaping (MEGASdk, any MEGARequestDelegate) -> Void = { _, _ in },
        requestResult: MockSdkRequestResult = .failure(MockError.failingError)
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
            folderInfo: MockFolderInfo(currentSize: currentSize)
        )
        
        let currentUserSource = CurrentUserSource(sdk: mockSdk)
        
        currentUserSource.setAccountDetails(
            (accountDetails ?? defaultAccountDetails(type: .free, nodeSizes: nodeSizes))
                .toAccountDetailsEntity()
        )
        
        return (AccountRepository(
            sdk: mockSdk,
            currentUserSource: currentUserSource,
            myChatFilesFolderNodeAccess: myChatFilesRootNodeAccess,
            backupsRootFolderNodeAccess: backupsRootNodeAccess
        ), mockSdk)
    }
    
    private func nodeAccess(for nodeHandle: UInt64) -> NodeAccessProtocol {
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
            type: .free,
            nodeSizes: nodeSizes
        )
    }
    
    private func randomAccountDetails() -> MockMEGAAccountDetails {
        MockMEGAAccountDetails(type: MEGAAccountType(rawValue: .random(in: 0...4)) ?? .free)
    }
}
