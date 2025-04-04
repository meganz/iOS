import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import XCTest

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
            XCTFail("Did not throw error! Expected to catch GenericErrorEntity.")
        } catch let error as ReportErrorEntity {
            XCTAssertNotNil(error)
        } catch {
            XCTFail("Invalid exception caught")
        }
    }
}
