import MEGADomain
import MEGADomainMock
import XCTest

final class WaitingRoomUseCaseTest: XCTestCase {
    public func testUserName_forUseNameTestUser_shouldMatch() {
        let userName = "Test User"
        let waitingRoomRepository = MockWaitingRoomRepository(userName: userName)
        let sut = WaitingRoomUseCase(waitingRoomRepo: waitingRoomRepository)
        
        XCTAssertEqual(sut.userName(), userName)
    }
    
    public func testJoinChat_onSuccess_shouldReturnChatRoomAndMatch() async throws {
        let chatRoom = ChatRoomEntity(chatId: 100)
        let waitingRoomRepository = MockWaitingRoomRepository(joinChatResult: .success(chatRoom))
        let sut = WaitingRoomUseCase(waitingRoomRepo: waitingRoomRepository)
        
        let myChatRoom = try await sut.joinChat(forChatId: 100, userHandle: 100)
        XCTAssertEqual(myChatRoom, chatRoom)
    }
}
