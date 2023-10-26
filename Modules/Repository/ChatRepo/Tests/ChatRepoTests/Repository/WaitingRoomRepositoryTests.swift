import ChatRepo
import ChatRepoMock
import XCTest

final class WaitingRoomRepositoryTests: XCTestCase {
    
    func testJoinChat_onChatRoomInPreviewMode_shouldCallAutoJoinPublicChat() async throws {
        let chatRoom = MockChatRoom(isPreview: true)
        let chatSDK = MockChatSDK(chatRoom: chatRoom)
        let sut = WaitingRoomRepository(chatSdk: chatSDK)
        
        _ = try await sut.joinChat(forChatId: chatRoom.chatId, userHandle: 1)
        
        XCTAssertEqual(chatSDK.autojoinPublicChatCalled, 1)
        XCTAssertEqual(chatSDK.autorejoinPublicChatCalled, 0)
    }
    
    func testJoinChat_onChatRoomActive_shouldCallAutoJoinPublicChat() async throws {
        let chatRoom = MockChatRoom(isActive: true)
        let chatSDK = MockChatSDK(chatRoom: chatRoom)
        let sut = WaitingRoomRepository(chatSdk: chatSDK)
        
        _ = try await sut.joinChat(forChatId: chatRoom.chatId, userHandle: 1)
        
        XCTAssertEqual(chatSDK.autojoinPublicChatCalled, 1)
        XCTAssertEqual(chatSDK.autorejoinPublicChatCalled, 0)
    }
    
    func testJoinChat_onChatRoomNotInPreviewModeAndNotActive_shouldCallAutoRejoinPublicChat() async throws {
        let chatRoom = MockChatRoom(isPreview: false, isActive: false)
        let chatSDK = MockChatSDK(chatRoom: chatRoom)
        let sut = WaitingRoomRepository(chatSdk: chatSDK)
        
        _ = try await sut.joinChat(forChatId: chatRoom.chatId, userHandle: 1)
        
        XCTAssertEqual(chatSDK.autojoinPublicChatCalled, 0)
        XCTAssertEqual(chatSDK.autorejoinPublicChatCalled, 1)
    }
}
