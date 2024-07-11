import MEGADomain

final class ContactsGroupCellViewModel {
    private let chatRoomUseCase: any ChatRoomUseCaseProtocol
    private let accountUseCase: any AccountUseCaseProtocol
    private var chatRoomId: HandleEntity?

    var title: String
    var isKeyRotationImageHidden: Bool
    var backAvatarHandle: HandleEntity = .invalidHandle
    var frontAvatarHandle: HandleEntity = .invalidHandle
    
    init(
        chatListItem: ChatListItemEntity,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        accountUseCase: some AccountUseCaseProtocol
    ) {
        self.title = chatListItem.title ?? ""
        self.isKeyRotationImageHidden = chatListItem.publicChat
        self.chatRoomId = chatListItem.chatId
        
        self.chatRoomUseCase = chatRoomUseCase
        self.accountUseCase = accountUseCase
        
        configureAvatarHandles()
    }
    
    private func configureAvatarHandles() {
        guard let chatRoomId = chatRoomId,
              let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatRoomId) else {
            return
        }

        backAvatarHandle = chatRoom.peers.first?.handle ?? .invalidHandle
        frontAvatarHandle = chatRoom.peers.count > 1 ? chatRoom.peers[1].handle : accountUseCase.currentUserHandle ?? .invalidHandle
    }
}
