import MEGADomain
import MEGADomainMock
import MEGASwift
import MEGATest
import Testing
import XCTest

final class AccountStorageUseCaseTests: XCTestCase {
    private let currentTestDate = Date()
    
    // MARK: - Storage Quota Tests
    
    func testWillStorageQuotaExceed_ifUserHasAlreadyReachedQuota_shouldReturnTrue() {
        let (sut, _) = makeSUT(storageUsed: 1000)
        let result = sut.willStorageQuotaExceed(after: makeNodesToBeImported())
        XCTAssertTrue(result)
    }
    
    func testWillStorageQuotaExceed_ifUserHasBelowQuotaAndImportWillGoOverQuota_shouldReturnTrue() {
        let (sut, _) = makeSUT(storageUsed: 1000)
        let result = sut.willStorageQuotaExceed(after: makeNodesToBeImported())
        XCTAssertTrue(result)
    }
    
    func testWillStorageQuotaExceed_ifUserHasBelowQuotaAndImportWillEqualQuota_shouldReturnFalse() {
        let (sut, _) = makeSUT(storageUsed: 600)
        let result = sut.willStorageQuotaExceed(after: makeNodesToBeImported())
        XCTAssertFalse(result)
    }
    
    func testWillStorageQuotaExceed_ifUserHasBelowQuotaAndImportWillBeBelowQuotaLimit_shouldReturnFalse() {
        let (sut, _) = makeSUT(storageUsed: 400)
        let result = sut.willStorageQuotaExceed(after: makeNodesToBeImported())
        XCTAssertFalse(result)
    }
    
    // MARK: - Storage Status Updates
    
    func testOnStorageStatusUpdates_whenStorageStatusIsUpdated_shouldEmitCorrectValues() async {
        let expectedStatusUpdates: [StorageStatusEntity] = [.noStorageProblems, .almostFull, .full]
        let (sut, _) = makeSUT(onStorageStatusUpdates: AsyncStream { continuation in
            for status in expectedStatusUpdates {
                continuation.yield(status)
            }
            continuation.finish()
        }.eraseToAnyAsyncSequence())
        
        var receivedStatusUpdates: [StorageStatusEntity] = []
        for await status in sut.onStorageStatusUpdates {
            receivedStatusUpdates.append(status)
        }
        
        XCTAssertEqual(receivedStatusUpdates, expectedStatusUpdates)
    }
    
    // MARK: - Current Storage Status Tests
    
    func testCurrentStorageStatus_whenRepositoryHasStatus_shouldReturnCorrectStorageStatus() {
        let expectedStatus: StorageStatusEntity = .almostFull
        let (sut, _) = makeSUT(currentStorageStatus: expectedStatus)
        XCTAssertEqual(sut.currentStorageStatus, expectedStatus)
    }
    
    func testCurrentStorageStatus_whenIsUnlimitedStorageAccount_shouldReturnNoStorageProblems() {
        let (sut, _) = makeSUT(currentStorageStatus: .full, isUnlimitedStorageAccount: true)
        XCTAssertEqual(sut.currentStorageStatus, .noStorageProblems, "Expected no storage problems when account has unlimited storage.")
    }
    
    // MARK: - Should Refresh Storage Status Tests
    
    func testShouldRefreshStorageStatus_whenShouldRefreshIsTrue_shouldReturnTrue() {
        let (sut, _) = makeSUT(shouldRefreshStorageStatus: true)
        XCTAssertTrue(sut.shouldRefreshStorageStatus)
    }
    
    func testShouldRefreshStorageStatus_whenShouldRefreshIsFalse_shouldReturnFalse() {
        let (sut, _) = makeSUT(shouldRefreshStorageStatus: false)
        XCTAssertFalse(sut.shouldRefreshStorageStatus)
    }
    
    // MARK: - Should Show Storage Banner Tests
    
    func testShouldShowStorageBanner_whenLastDismissDateIsLessThan24HoursAgo_shouldReturnFalse() {
        let dateLessThan24HoursAgo = Calendar.current.date(byAdding: .hour, value: -10, to: currentTestDate)
        let (sut, _) = makeSUT(currentStorageStatus: .almostFull, lastStorageBannerDismissedDate: dateLessThan24HoursAgo, currentDate: { [currentTestDate] in
            currentTestDate
        })
        XCTAssertFalse(sut.shouldShowStorageBanner, "Expected banner to not show when last dismiss date is less than 24 hours ago.")
    }
    
    func testShouldShowStorageBanner_whenLastDismissDateIsMoreThan24HoursAgo_shouldReturnTrue() {
        let dateMoreThan24HoursAgo = Calendar.current.date(byAdding: .hour, value: -25, to: currentTestDate)
        let (sut, _) = makeSUT(currentStorageStatus: .almostFull, lastStorageBannerDismissedDate: dateMoreThan24HoursAgo, currentDate: { [currentTestDate] in
            currentTestDate
        })
        XCTAssertTrue(sut.shouldShowStorageBanner, "Expected banner to show when last dismiss date is more than 24 hours ago.")
    }
    
    func testShouldShowStorageBanner_whenStorageStatusIsAlmostFullAndNoDismissDate_shouldReturnTrue() {
        let (sut, _) = makeSUT(currentStorageStatus: .almostFull, lastStorageBannerDismissedDate: nil, currentDate: { [currentTestDate] in
            currentTestDate
        })
        XCTAssertTrue(sut.shouldShowStorageBanner, "Expected banner to show when storage status is almost full and no dismiss date.")
    }
    
    func testShouldShowStorageBanner_whenStorageStatusIsFull_shouldReturnTrue() {
        let (sut, _) = makeSUT(currentStorageStatus: .full, currentDate: { [currentTestDate] in
            currentTestDate
        })
        XCTAssertTrue(sut.shouldShowStorageBanner, "Expected banner to show when storage status is full.")
    }
    
    func testShouldShowStorageBanner_whenStorageStatusIsNoStorageProblems_shouldReturnFalse() {
        let (sut, _) = makeSUT(currentStorageStatus: .noStorageProblems, currentDate: { [currentTestDate] in
            currentTestDate
        })
        XCTAssertFalse(sut.shouldShowStorageBanner, "Expected banner to not show when storage status is no storage problems.")
    }
    
    // MARK: - Update Last Storage Banner Dismiss Date Tests
    
    func testUpdateLastStorageBannerDismissDate_shouldUpdateToCurrentDate() throws {
        let (sut, preferenceUC) = makeSUT(currentDate: { [currentTestDate] in
            currentTestDate
        })
        sut.updateLastStorageBannerDismissDate()
        let updatedDate = try XCTUnwrap(preferenceUC.dict[.lastStorageBannerDismissedDate] as? Date)
        
        XCTAssertNotNil(updatedDate, "Expected date to be updated, but it was nil.")
        XCTAssertEqual(updatedDate, currentTestDate, "Expected updated date to be equal to the current date.")
    }
    
    func testUpdateLastStorageBannerDismissDate_shouldOverwritePreviousDate() throws {
        let oldDate = Calendar.current.date(byAdding: .day, value: -2, to: currentTestDate)!
        let (sut, preferenceUC) = makeSUT(currentStorageStatus: .almostFull, lastStorageBannerDismissedDate: oldDate, currentDate: { [currentTestDate] in
            currentTestDate
        })
        sut.updateLastStorageBannerDismissDate()
        let updatedDate = try XCTUnwrap(preferenceUC.dict[.lastStorageBannerDismissedDate] as? Date)
        
        XCTAssertNotNil(updatedDate, "Expected date to be updated, but it was nil.")
        XCTAssertEqual(updatedDate, currentTestDate, "Expected updated date to be equal to the current date.")
    }
    
    // MARK: - Helpers
    
    func makeSUT(
        storageUsed: Int64 = 0,
        storageMax: Int64 = 1000,
        shouldRefreshStorageStatus: Bool = false,
        onStorageStatusUpdates: AnyAsyncSequence<StorageStatusEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        currentStorageStatus: StorageStatusEntity = .noStorageProblems,
        lastStorageBannerDismissedDate: Date? = nil,
        isUnlimitedStorageAccount: Bool = false,
        currentDate: @Sendable @escaping () -> Date = { Date() }
    ) -> (AccountStorageUseCase, MockPreferenceUseCase) {
        let accountRepository = MockAccountRepository(
            shouldRefreshStorageStatus: shouldRefreshStorageStatus,
            currentAccountDetails: AccountDetailsEntity.build(
                storageUsed: storageUsed,
                storageMax: storageMax
            ),
            currentStorageStatus: currentStorageStatus,
            isUnlimitedStorageAccount: isUnlimitedStorageAccount,
            onStorageStatusUpdates: onStorageStatusUpdates
        )
        
        let mockPreferenceUseCase = MockPreferenceUseCase()
        if let lastDismissedDate = lastStorageBannerDismissedDate {
            mockPreferenceUseCase.dict[.lastStorageBannerDismissedDate] = lastDismissedDate
        }
        
        let sut = AccountStorageUseCase(
            accountRepository: accountRepository,
            preferenceUseCase: mockPreferenceUseCase,
            currentDate: currentDate
        )
        
        return (sut, mockPreferenceUseCase)
    }
    
    func makeNodesToBeImported() -> [NodeEntity] {
        [
            NodeEntity(handle: 0, size: 100),
            NodeEntity(handle: 1, size: 100),
            NodeEntity(handle: 2, size: 100),
            NodeEntity(handle: 3, size: 100)
        ]
    }
    
    private func assertIsUnlimitedStorageAccount(
        for accountType: String,
        isUnlimited: Bool,
        line: UInt = #line
    ) {
        let sut = MockAccountRepository(isUnlimitedStorageAccount: isUnlimited)
        XCTAssertEqual(sut.isUnlimitedStorageAccount, isUnlimited, "Expected isUnlimitedStorageAccount to be \(isUnlimited) for \(accountType) account", line: line)
    }
}

@Suite("AccountStorageUseCase Tests")
struct AccountStorageUseCaseTestsSuite {
    
    @Test("should return current status from repository",
          arguments: [true, false])
    func isPaywalled(expected: Bool) async throws {
        let repository = MockAccountRepository(isPaywalled: expected)
        let sut = AccountStorageUseCaseTestsSuite
            .makeSUT(accountRepository: repository)
        
        #expect(sut.isPaywalled == expected)
    }
    
    private static func makeSUT(
        accountRepository: some AccountRepositoryProtocol = MockAccountRepository(),
        preferenceUseCase: some PreferenceUseCaseProtocol = MockPreferenceUseCase()
    ) -> AccountStorageUseCase {
        .init(
            accountRepository: accountRepository,
            preferenceUseCase: preferenceUseCase)
    }
}
