import ChatRepoMock
@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGATest
import XCTest

final class ChatRoomAvatarViewModelTests: XCTestCase {
    @MainActor
    func testLoadAvatar_forOneToOneChat_shouldUpdateOneAvatarAndMatch() async {
        let chatRoom = ChatRoomEntity(chatType: .oneToOne)
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: "base64Handle")
        let mockAccountUseCase = MockAccountUseCase(currentUser: UserEntity(handle: 1))
        let userImageUseCase = MockUserImageUseCase()
        let sut = makeChatRoomAvatarViewModel(
            chatRoom: chatRoom,
            userImageUseCase: userImageUseCase,
            accountUseCase: mockAccountUseCase,
            megaHandleUseCase: megaHandleUseCase
        )
        
        let userImage = try? await sut.createAvatar(withHandle: 1)
        await sut.loadAvatar(isRightToLeftLanguage: false)
        
        let expected = ChatListItemAvatarEntity(
            primaryAvatarData: userImage?.pngData(),
            secondaryAvatarData: nil
        )
        let result = sut.chatListItemAvatar
        
        XCTAssertEqual(result, expected)
    }
    
    @MainActor
    func testLoadAvatar_forOnePeerChat_shouldUpdateOneAvatarAndMatch() async {
        let peer = ChatRoomEntity.Peer(handle: 200, privilege: .standard)
        let chatRoom = ChatRoomEntity(peerCount: 1, chatType: .group, peers: [peer])
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: "base64Handle")
        let userImageUseCase = MockUserImageUseCase()
        let chatRoomUserUseCase = MockChatRoomUserUseCase(
            userDisplayNamesForPeersResult: .success([(200, "Peer1")])
        )
        let sut = makeChatRoomAvatarViewModel(
            chatRoom: chatRoom,
            chatRoomUserUseCase: chatRoomUserUseCase, 
            userImageUseCase: userImageUseCase,
            megaHandleUseCase: megaHandleUseCase
        )
        
        let userImage = try? await sut.createAvatar(withHandle: 200)
        await sut.loadAvatar(isRightToLeftLanguage: false)
        
        let expected = ChatListItemAvatarEntity(
            primaryAvatarData: userImage?.pngData(),
            secondaryAvatarData: nil
        )
        let result = sut.chatListItemAvatar
        XCTAssertEqual(result, expected)
    }
    
    @MainActor
    func testLoadAvatar_forTwoPeerChat_shouldUpdateTwoAvatarAndMatch() async {
        let peer1 = ChatRoomEntity.Peer(handle: 201, privilege: .standard)
        let peer2 = ChatRoomEntity.Peer(handle: 202, privilege: .standard)
        let chatRoom = ChatRoomEntity(peerCount: 2, chatType: .group, peers: [peer1, peer2])
        let megaHandleUseCase = MockMEGAHandleUseCase(base64Handle: "base64Handle")
        let userImageUseCase = MockUserImageUseCase()
        let chatRoomUserUseCase = MockChatRoomUserUseCase(
            userDisplayNamesForPeersResult: .success([(201, "Peer2"), (202, "Peer2")])
        )
        let sut = makeChatRoomAvatarViewModel(
            chatRoom: chatRoom,
            chatRoomUserUseCase: chatRoomUserUseCase,
            userImageUseCase: userImageUseCase,
            megaHandleUseCase: megaHandleUseCase
        )
        
        let userImage = try? await sut.createAvatar(withHandle: 201)
        await sut.loadAvatar(isRightToLeftLanguage: false)
        
        let expected = ChatListItemAvatarEntity(
            primaryAvatarData: userImage?.pngData(),
            secondaryAvatarData: userImage?.pngData()
        )
        let result = sut.chatListItemAvatar
        XCTAssertEqual(result, expected)
    }
    
    // MARK: - Private
    
    @MainActor
    private func makeChatRoomAvatarViewModel(
        title: String = "Test",
        peerHandle: HandleEntity = 1,
        chatRoom: ChatRoomEntity = ChatRoomEntity(),
        chatRoomUseCase: some ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol = MockChatRoomUserUseCase(),
        userImageUseCase: some UserImageUseCaseProtocol = MockUserImageUseCase(),
        chatUseCase: some ChatUseCaseProtocol = MockChatUseCase(),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        megaHandleUseCase: some MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
        chatListItemCacheUseCase: some ChatListItemCacheUseCaseProtocol = MockChatListItemCacheUseCase(),
        chatListItemAvatar: ChatListItemAvatarEntity? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) -> ChatRoomAvatarViewModel {
        ChatRoomAvatarViewModel(
            title: title,
            peerHandle: peerHandle,
            chatRoom: chatRoom,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            userImageUseCase: userImageUseCase,
            chatUseCase: chatUseCase,
            accountUseCase: accountUseCase,
            megaHandleUseCase: megaHandleUseCase,
            chatListItemCacheUseCase: chatListItemCacheUseCase,
            chatListItemAvatar: chatListItemAvatar
        )
    }
}
