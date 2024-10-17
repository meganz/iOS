import MEGADomain
import MEGADomainMock
import MEGASwift
import MEGATest
import XCTest

final class AccountStorageUseCaseTests: XCTestCase {
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
    
    func testCurrentStorageStatus_whenRepositoryHasStatus_shouldReturnCorrectStorageStatus() {
        let expectedStatus: StorageStatusEntity = .almostFull
        let (sut, _) = makeSUT(currentStorageStatus: expectedStatus)
        XCTAssertEqual(sut.currentStorageStatus, expectedStatus)
    }
    
    func testShouldRefreshStorageStatus_whenShouldRefreshIsTrue_shouldReturnTrue() {
        let (sut, _) = makeSUT(shouldRefreshStorageStatus: true)
        XCTAssertTrue(sut.shouldRefreshStorageStatus)
    }
    
    func testShouldRefreshStorageStatus_whenShouldRefreshIsFalse_shouldReturnFalse() {
        let (sut, _) = makeSUT(shouldRefreshStorageStatus: false)
        XCTAssertFalse(sut.shouldRefreshStorageStatus)
    }
    
    func testShouldShowStorageBanner_whenLastDismissDateIsNil_shouldReturnTrue() {
        let (sut, _) = makeSUT()
        XCTAssertTrue(sut.shouldShowStorageBanner, "Expected banner to show when dismiss date is nil.")
    }
    
    func testShouldShowStorageBanner_whenLastDismissDateIsMoreThan24HoursAgo_shouldReturnTrue() {
        let dateMoreThan24HoursAgo = Calendar.current.date(byAdding: .hour, value: -25, to: Date())
        let (sut, _) = makeSUT(lastStorageBannerDismissedDate: dateMoreThan24HoursAgo)
        XCTAssertTrue(sut.shouldShowStorageBanner, "Expected banner to show when last dismiss date is more than 24 hours ago.")
    }
    
    func testShouldShowStorageBanner_whenLastDismissDateIsLessThan24HoursAgo_shouldReturnFalse() {
        let dateLessThan24HoursAgo = Calendar.current.date(byAdding: .hour, value: -10, to: Date())
        let (sut, _) = makeSUT(lastStorageBannerDismissedDate: dateLessThan24HoursAgo)
        XCTAssertFalse(sut.shouldShowStorageBanner, "Expected banner to not show when last dismiss date is less than 24 hours ago.")
    }
    
    func testUpdateLastStorageBannerDismissDate_shouldUpdateToCurrentDate() throws {
        let (sut, preferenceUC) = makeSUT()
        let beforeUpdateDate = Date()
        sut.updateLastStorageBannerDismissDate()
        let afterUpdateDate = try XCTUnwrap(preferenceUC.dict[.lastStorageBannerDismissedDate] as? Date)

        XCTAssertNotNil(afterUpdateDate, "Expected date to be updated, but it was nil.")
        XCTAssertTrue(afterUpdateDate >= beforeUpdateDate, "Expected updated date to be greater than or equal to the current date.")
    }
    
    func testUpdateLastStorageBannerDismissDate_shouldOverwritePreviousDate() throws {
        let oldDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let (sut, preferenceUC) = makeSUT(lastStorageBannerDismissedDate: oldDate)
        sut.updateLastStorageBannerDismissDate()
        let updatedDate = try XCTUnwrap(preferenceUC.dict[.lastStorageBannerDismissedDate] as? Date)

        XCTAssertNotNil(updatedDate, "Expected date to be updated, but it was nil.")
        XCTAssertTrue(updatedDate > oldDate, "Expected updated date to be more recent than the old date.")
    }
    
    func testIsUnlimitedStorageAccount_whenAccountTypeIsProvided_shouldReturnExpectedResult() {
        assertIsUnlimitedStorageAccount(for: "Pro Flexi or Bussiness", isUnlimited: true)
        assertIsUnlimitedStorageAccount(for: "Free or Other Pro accounts", isUnlimited: false)
        assertIsUnlimitedStorageAccount(for: "No account details", isUnlimited: false)
    }
    
    // MARK: - Helpers
    
    func makeSUT(
        storageUsed: Int64 = 0,
        storageMax: Int64 = 1000,
        shouldRefreshStorageStatus: Bool = false,
        onStorageStatusUpdates: AnyAsyncSequence<StorageStatusEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        currentStorageStatus: StorageStatusEntity = .noStorageProblems,
        lastStorageBannerDismissedDate: Date? = nil
    ) -> (AccountStorageUseCase, MockPreferenceUseCase) {
        let accountRepository = MockAccountRepository(
            shouldRefreshStorageStatus: shouldRefreshStorageStatus,
            currentAccountDetails: AccountDetailsEntity.build(
                storageUsed: storageUsed,
                storageMax: storageMax
            ),
            currentStorageStatus: currentStorageStatus,
            onStorageStatusUpdates: onStorageStatusUpdates
        )
        
        let mockPreferenceUseCase = MockPreferenceUseCase()
        if let lastDismissedDate = lastStorageBannerDismissedDate {
            mockPreferenceUseCase.dict[.lastStorageBannerDismissedDate] = lastDismissedDate
        }
        
        let sut = AccountStorageUseCase(
            accountRepository: accountRepository,
            preferenceUseCase: mockPreferenceUseCase
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
