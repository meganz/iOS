import ChatRepo
@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class ContactsGroupCellViewModelTests: XCTestCase {
    let moderatorPeer = ChatRoomEntity.Peer(handle: 123, privilege: .moderator)
    let auxPeer = ChatRoomEntity.Peer(handle: 456, privilege: .standard)
    let defaultChatTitle = "Test Chat"
    
    func testInitialization_withPublicChat_shouldHideKeyRotationImage() {
        let (sut, _) = makeSUT(publicChat: true)
        
        XCTAssertTrue(sut.isKeyRotationImageHidden)
    }
    
    func testInitialization_withPrivateChat_shouldShowKeyRotationImage() {
        let (sut, _) = makeSUT(publicChat: false)
        
        XCTAssertFalse(sut.isKeyRotationImageHidden)
    }
    
    func testInitialization_withChatRoom_shouldConfigureAvatarHandles() {
        let chatRoom = ChatRoomEntity(peers: [
            moderatorPeer, auxPeer
        ])
        let (sut, _) = makeSUT(chatRoom: chatRoom)
        
        XCTAssertEqual(sut.backAvatarHandle, moderatorPeer.handle)
        XCTAssertEqual(sut.frontAvatarHandle, auxPeer.handle)
    }
    
    func testInitialization_withSinglePeer_shouldUseCurrentUserHandleForFrontAvatar() {
        let chatRoom = ChatRoomEntity(peers: [moderatorPeer])
        let currentUserHandle: HandleEntity = 789
        let (sut, _) = makeSUT(chatRoom: chatRoom, currentUserHandle: currentUserHandle)
        
        XCTAssertEqual(sut.backAvatarHandle, moderatorPeer.handle)
        XCTAssertEqual(sut.frontAvatarHandle, currentUserHandle)
    }
    
    func testInitialization_withNoChatRoom_shouldSetInvalidHandles() {
        let (sut, _) = makeSUT()
        
        XCTAssertEqual(sut.backAvatarHandle, HandleEntity.invalid)
        XCTAssertEqual(sut.frontAvatarHandle, HandleEntity.invalid)
    }
    
    func testInitialization_withEmptyChatRoomPeers_shouldSetInvalidHandles() {
        let chatRoom = ChatRoomEntity(peers: [])
        let (sut, _) = makeSUT(chatRoom: chatRoom)
        
        XCTAssertEqual(sut.backAvatarHandle, HandleEntity.invalid)
        XCTAssertEqual(sut.frontAvatarHandle, HandleEntity.invalid)
    }
    
    func testInitialization_withNilTitle_shouldSetEmptyTitle() {
        let (sut, _) = makeSUT(title: nil)
        
        XCTAssertEqual(sut.title, "")
    }
    
    // MARK: - Helper Functions

    private func makeSUT(
        chatId: HandleEntity = 1,
        title: String? = "",
        publicChat: Bool = false,
        chatRoom: ChatRoomEntity? = nil,
        currentUserHandle: HandleEntity = .invalidHandle
    ) -> (sut: ContactsGroupCellViewModel, mockChatRoomUseCase: MockChatRoomUseCase) {
        
        let chatListItem = ChatListItemEntity(
            chatId: chatId,
            title: title,
            publicChat: publicChat
        )
        let mockChatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: chatRoom)
        let mockAccountUseCase = MockAccountUseCase(currentUser: UserEntity(handle: currentUserHandle))
        
        let sut = ContactsGroupCellViewModel(
            chatListItem: chatListItem,
            chatRoomUseCase: mockChatRoomUseCase,
            accountUseCase: mockAccountUseCase
        )
        
        trackForMemoryLeaks(on: sut)
        return (sut, mockChatRoomUseCase)
    }
}
