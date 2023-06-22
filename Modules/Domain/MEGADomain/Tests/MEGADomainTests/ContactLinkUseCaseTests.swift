import MEGADomain
import MEGADomainMock
import XCTest

final class ContactLinkUseCaseTests: XCTestCase {
    
    func testContactLinkQuery() async throws {
        let repo = MockContactLinkRepository.newRepo
        let sut = ContactLinkUseCase(repo: repo)
        
        let contactLinkInfo = try await sut.contactLinkQuery(handle: HandleEntity())
        
        XCTAssertNotNil(contactLinkInfo)
        let email = try XCTUnwrap(contactLinkInfo?.email)
        XCTAssertFalse(email.isEmpty)
        let name = try XCTUnwrap(contactLinkInfo?.name)
        XCTAssertFalse(name.isEmpty)
    }
}
