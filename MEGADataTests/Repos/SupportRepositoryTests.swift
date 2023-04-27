import MEGADomainMock
import MEGADomain
import XCTest
@testable import MEGA
import MEGADataMock

final class SupportRepositoryTests: XCTestCase {
    private var sdk: MockSdk!
    private var repo: SupportRepository!
    
    func testCreateSupportTicket_onFinished_shouldSucceed() async throws {
        sdk = MockSdk()
        repo = SupportRepository(sdk: sdk)
        try await repo.createSupportTicket(withMessage: "This is a test")
    }
    
    func testCreateSupportTicket_onFinished_shouldFail() async throws {
        do {
            sdk = MockSdk(createSupportTicketError: .apiETooMany)
            repo = SupportRepository(sdk: sdk)
            try await repo.createSupportTicket(withMessage: "This is a test")
            XCTFail()
        } catch let error as GenericErrorEntity {
            XCTAssertNotNil(error)
        } catch {
            XCTFail("Invalid exception caught")
        }
    }
}
