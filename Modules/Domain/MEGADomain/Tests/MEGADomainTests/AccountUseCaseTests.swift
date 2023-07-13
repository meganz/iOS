import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

final class AccountUseCaseTests: XCTestCase {

    func testUpgradeSecurity_shouldReturnSuccess() async throws {
        let sut = AccountUseCase(repository: MockAccountRepository(isUpgradeSecuritySuccess: true))
        let isSuccess = try await sut.upgradeSecurity()
        XCTAssertTrue(isSuccess)
    }
    
    func testCurrentAccountDetails_shouldReturnCurrentAccountDetails() {
        let accountDetails = AccountDetailsEntity.random
        let sut = AccountUseCase(repository: MockAccountRepository(currentAccountDetails: accountDetails))
        
        XCTAssertEqual(sut.currentAccountDetails, accountDetails)
    }
    
    func testRefreshCurrentAccountDetails_whenSuccess_shouldReturnAccountDetails() async throws {
        let accountDetails = AccountDetailsEntity.random
        let sut = AccountUseCase(repository: MockAccountRepository(accountDetailsResult: .success(accountDetails)))
        
        let currentAccountDetails = try await sut.refreshCurrentAccountDetails()
        XCTAssertEqual(currentAccountDetails, accountDetails)
    }
    
    func testRefreshCurrentAccountDetails_whenFails_shouldThrowGenericError() async {
        let sut = AccountUseCase(repository: MockAccountRepository(accountDetailsResult: .failure(.generic)))
        
        await XCTAsyncAssertThrowsError(try await sut.refreshCurrentAccountDetails()) { errorThrown in
            XCTAssertEqual(errorThrown as? AccountDetailsErrorEntity, .generic)
        }
    }
}
