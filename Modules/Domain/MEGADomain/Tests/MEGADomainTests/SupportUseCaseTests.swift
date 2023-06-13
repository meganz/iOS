import MEGADomain
import MEGADomainMock
import XCTest

final class SupportUseCaseTests: XCTestCase {
    
    func testCreateSupportTicket_whenInjected_doesNotAlterMessageFormat() async {
        let sampleMessage = "a message"
        let (sut, repositorySpy) = makeSUT()
        
        _ = try? await sut.createSupportTicket(withMessage: sampleMessage)
        
        XCTAssertEqual(repositorySpy.messages, [ .createSupportTicket(message: sampleMessage) ])
    }
    
    // MARK: - Helpers
    
    private func makeSUT() -> (sut: SupportUseCase, repository: MockSupportRepository) {
        let repository = MockSupportRepository()
        let sut = SupportUseCase(repo: repository)
        return (sut, repository)
    }
}
