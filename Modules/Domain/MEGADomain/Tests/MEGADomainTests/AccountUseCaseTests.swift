import MEGADomain
import MEGADomainMock
import XCTest

final class AccountUseCaseTests: XCTestCase {

    func testUpgradeSecurity_shouldReturnSuccess() async throws {
        let sut = AccountUseCase(repository: MockAccountRepository(isUpgradeSecuritySuccess: true))
        let isSuccess = try await sut.upgradeSecurity()
        XCTAssertTrue(isSuccess)
    }
    
}
