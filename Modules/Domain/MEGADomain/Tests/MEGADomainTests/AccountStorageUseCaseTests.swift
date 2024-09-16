import MEGADomain
import MEGADomainMock
import MEGASwift
import MEGATest
import XCTest

final class AccountStorageUseCaseTests: XCTestCase {
    func testWillStorageQuotaExceed_ifUserHasAlreadyReachedQuota_shouldReturnTrue() {
        let sut = makeSUT(storageUsed: 1000)
        let result = sut.willStorageQuotaExceed(after: makeNodesToBeImported())
        XCTAssertTrue(result)
    }
    
    func testWillStorageQuotaExceed_ifUserHasBelowQuotaAndImportWillGoOverQuota_shouldReturnTrue() {
        let sut = makeSUT(storageUsed: 1000)
        let result = sut.willStorageQuotaExceed(after: makeNodesToBeImported())
        XCTAssertTrue(result)
    }
    
    func testWillStorageQuotaExceed_ifUserHasBelowQuotaAndImportWillEqualQuota_shouldReturnFalse() {
        let sut = makeSUT(storageUsed: 600)
        let result = sut.willStorageQuotaExceed(after: makeNodesToBeImported())
        XCTAssertFalse(result)
    }
    
    func testWillStorageQuotaExceed_ifUserHasBelowQuotaAndImportWillBeBelowQuotaLimit_shouldReturnFalse() {
        let sut = makeSUT(storageUsed: 400)
        let result = sut.willStorageQuotaExceed(after: makeNodesToBeImported())
        XCTAssertFalse(result)
    }
    
    func testOnStorageStatusUpdates_whenStorageStatusIsUpdated_shouldEmitCorrectValues() async {
        let expectedStatusUpdates: [StorageStatusEntity] = [.noStorageProblems, .almostFull, .full]
        let sut = makeSUT(onStorageStatusUpdates: AsyncStream { continuation in
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
        let sut = makeSUT(currentStorageStatus: expectedStatus)
        XCTAssertEqual(sut.currentStorageStatus, expectedStatus)
    }
    
    // MARK: - Helpers
    func makeSUT(
        storageUsed: Int64 = 0,
        storageMax: Int64 = 1000,
        onStorageStatusUpdates: AnyAsyncSequence<StorageStatusEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        currentStorageStatus: StorageStatusEntity = .noStorageProblems
    ) -> AccountStorageUseCase<MockAccountRepository> {
        let accountRepository = MockAccountRepository(
            currentAccountDetails: AccountDetailsEntity.build(
                storageUsed: storageUsed,
                storageMax: storageMax
            ),
            currentStorageStatus: currentStorageStatus,
            onStorageStatusUpdates: onStorageStatusUpdates
        )
        return AccountStorageUseCase(accountRepository: accountRepository)
    }
    
    func makeNodesToBeImported() -> [NodeEntity] {
        [
            NodeEntity(handle: 0, size: 100),
            NodeEntity(handle: 1, size: 100),
            NodeEntity(handle: 2, size: 100),
            NodeEntity(handle: 3, size: 100)
        ]
    }
}
