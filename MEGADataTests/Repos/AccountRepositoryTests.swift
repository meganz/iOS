import XCTest
import MEGADomainMock
import MEGADomain
@testable import MEGA

final class AccountRepositoryTests: XCTestCase {
    func testUpgradeSecurity_shouldReturnSuccess() async throws {
        let repo = AccountRepository(sdk: MockSdk())
        
        let isSuccess = try await repo.upgradeSecurity()
        XCTAssertTrue(isSuccess)
    }
}

