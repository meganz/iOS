import MEGADomain
import MEGADomainMock
import XCTest

final class UserInviteUseCaseTests: XCTestCase {

    func testSendInvite_whenSuccess_shouldNotThrow() async {
        let mockRepo = MockUserInviteRepository(requestResult: .success)
        let sut = UserInviteUseCase(repo: mockRepo)
        
        await XCTAsyncAssertNoThrow(try await sut.sendInvite(forEmail: "test@mega.nz"))
    }

    func testSendInvite_whenFailed_shouldThrowInviteErrorEntity() async {
        let mockRepo = MockUserInviteRepository(requestResult: .failure(randomError()))
        let sut = UserInviteUseCase(repo: mockRepo)
        
        await XCTAsyncAssertThrowsError(try await sut.sendInvite(forEmail: "test@mega.nz")) { errorThrown in
            XCTAssertTrue(errorThrown is InviteErrorEntity)
        }
    }
    
    // MARK: - Helper
    private func randomError() -> InviteErrorEntity {
        [InviteErrorEntity.alreadyAContact,
         InviteErrorEntity.isInOutgoingContactRequest,
         InviteErrorEntity.ownEmailEntered,
         InviteErrorEntity.generic("")].randomElement() ?? .generic("")
    }
}
