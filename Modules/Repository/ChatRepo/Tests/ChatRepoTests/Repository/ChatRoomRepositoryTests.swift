import ChatRepo
import ChatRepoMock
import MEGADomain
import XCTest

final class ChatRoomRepositoryTests: XCTestCase {
    func testUpdateChatPrivilege_forNewPrivilegeModerator_shouldUpdateToModerator() async throws {
        let chatSDK = MockChatSDK()
        let sut = ChatRoomRepository(
            sdk: chatSDK,
            chatConnectionStateUpdateProvider: ChatConnectionStateUpdateProvider(sdk: chatSDK)
        )

        let privilege = try await sut.updateChatPrivilege(chatRoom: MockChatRoom().toChatRoomEntity(), userHandle: 1, privilege: .moderator)
        
        XCTAssertEqual(privilege, .moderator)
    }
}
