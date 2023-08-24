import MEGADomain
import MEGADomainMock
import XCTest

final class ChatRoomUseCaseTests: XCTestCase {
    func testShouldOpenWaitingRoom_isNotModeratorAndWaitingRoomEnabled_shouldBeTrue() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, isWaitingRoomEnabled: true)
        let chatRoomRepository = MockChatRoomRepository(chatRoom: chatRoom)
        let sut = ChatRoomUseCase(chatRoomRepo: chatRoomRepository)
        
        XCTAssertTrue(sut.shouldOpenWaitingRoom(forChatId: HandleEntity()))
    }
    
    func testShouldOpenWaitingRoom_isModeratorAndWaitingRoomEnabled_shouldBeFalse() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isWaitingRoomEnabled: true)
        let chatRoomRepository = MockChatRoomRepository(chatRoom: chatRoom)
        let sut = ChatRoomUseCase(chatRoomRepo: chatRoomRepository)
        
        XCTAssertFalse(sut.shouldOpenWaitingRoom(forChatId: HandleEntity()))
    }
    
    func testShouldOpenWaitingRoom_isNotModeratorAndWaitingRoomNotEnabled_shouldBeFalse() {
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, isWaitingRoomEnabled: false)
        let chatRoomRepository = MockChatRoomRepository(chatRoom: chatRoom)
        let sut = ChatRoomUseCase(chatRoomRepo: chatRoomRepository)
        
        XCTAssertFalse(sut.shouldOpenWaitingRoom(forChatId: HandleEntity()))
    }
}
