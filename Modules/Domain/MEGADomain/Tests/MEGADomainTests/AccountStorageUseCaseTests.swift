import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

final class AccountStorageUseCaseTests: XCTestCase {

    func testWillStorageQuotaExceed_IfUserHasAlreadyReachedQuota_shouldReturnTrue() {
        
        // Arrange
        let accountRepository = MockAccountRepository(currentAccountDetails: AccountDetailsEntity(storageUsed: 1000, storageMax: 1000))
        let sut = AccountStorageUseCase(accountRepository: accountRepository)
        
        // Act
        let result = sut.willStorageQuotaExceed(after: makeNodesToBeImported())
        
        // Assert
        XCTAssertTrue(result)
    }
    
    func testWillStorageQuotaExceed_IfUserHasBelowQuotaAndImportWitllGoOverQouta_shouldReturnTrue() {
        
        // Arrange
        let accountRepository = MockAccountRepository(currentAccountDetails: AccountDetailsEntity(storageUsed: 1000, storageMax: 1000))
        let sut = AccountStorageUseCase(accountRepository: accountRepository)
        
        // Act
        let result = sut.willStorageQuotaExceed(after: makeNodesToBeImported())
        
        // Assert
        XCTAssertTrue(result)
    }
    
    func testWillStorageQuotaExceed_IfUserHasBelowQuotaAndImportWitllEqualQouta_shouldReturnFalse() {
        // Arrange
        let accountRepository = MockAccountRepository(currentAccountDetails: AccountDetailsEntity(storageUsed: 600, storageMax: 1000))
        let sut = AccountStorageUseCase(accountRepository: accountRepository)
        
        // Act
        let result = sut.willStorageQuotaExceed(after: makeNodesToBeImported())
        
        // Assert
        XCTAssertFalse(result)
    }
    
    func testWillStorageQuotaExceed_IfUserHasBelowQuotaAndImportWitllEqualBelowQoutaLimit_shouldReturnFalse() {
        // Arrange
        let accountRepository = MockAccountRepository(currentAccountDetails: AccountDetailsEntity(storageUsed: 400, storageMax: 1000))
        let sut = AccountStorageUseCase(accountRepository: accountRepository)
                
        // Act
        let result = sut.willStorageQuotaExceed(after: makeNodesToBeImported())
        
        // Assert
        XCTAssertFalse(result)
    }
}

fileprivate extension AccountStorageUseCaseTests {
    
    func makeNodesToBeImported() -> [NodeEntity] {
        [
            NodeEntity(handle: 0, size: 100),
            NodeEntity(handle: 1, size: 100),
            NodeEntity(handle: 2, size: 100),
            NodeEntity(handle: 3, size: 100)
        ]
    }
}
