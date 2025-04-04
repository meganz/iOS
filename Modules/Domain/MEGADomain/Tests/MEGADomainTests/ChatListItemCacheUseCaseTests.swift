import MEGADomain
import MEGADomainMock
import XCTest

final class ChatListItemCacheUseCaseTests: XCTestCase {
    func testDescription_notCached_shouldReturnNil() async {
        let chatId: HandleEntity = 100
        let chatListItemCacheRepository = MockChatListItemCacheRepository()
        let sut = makeChatListItemCacheUseCase(
            chatListItemCacheRepository: chatListItemCacheRepository
        )
        
        let chatListItem = ChatListItemEntity(chatId: chatId)
        let result = await sut.description(for: chatListItem)
        
        XCTAssertNil(result)
    }
    
    func testDescription_cached_shouldReturnCachedDescription() async {
        let chatId: HandleEntity = 100
        let chatListItemDescription = ChatListItemDescriptionEntity(description: "Test Description")
        let chatListItemCacheRepository = MockChatListItemCacheRepository(descriptionCache: [chatId: chatListItemDescription])
        let sut = makeChatListItemCacheUseCase(
            chatListItemCacheRepository: chatListItemCacheRepository
        )
        
        let chatListItem = ChatListItemEntity(chatId: chatId)
        let result = await sut.description(for: chatListItem)
        
        XCTAssertEqual(result, chatListItemDescription)
    }
    
    func testSetDescription_forNewChatListItemDescriptionEntity_shouldMatch() async {
        
        let sut = makeChatListItemCacheUseCase()
        
        let chatListItemDescription = ChatListItemDescriptionEntity(description: "Test Description")
        let chatId: HandleEntity = 100
        let chatListItem = ChatListItemEntity(chatId: chatId)
        await sut.setDescription(chatListItemDescription, for: chatListItem)
        
        let result = await sut.description(for: chatListItem)
        
        XCTAssertEqual(result, chatListItemDescription)
    }
    
    func testAvatar_forChatListItemAndNotCached_shouldReturnNil() async {
        let chatId: HandleEntity = 100
        let chatListItemCacheRepository = MockChatListItemCacheRepository()
        let sut = makeChatListItemCacheUseCase(
            chatListItemCacheRepository: chatListItemCacheRepository
        )
        
        let chatListItem = ChatListItemEntity(chatId: chatId)
        let result = await sut.avatar(for: chatListItem)
        
        XCTAssertNil(result)
    }
    
    func testAvatar_forScheduledMeetingAndNotCached_shouldReturnNil() async {
        let chatId: HandleEntity = 100
        let chatListItemCacheRepository = MockChatListItemCacheRepository()
        let sut = makeChatListItemCacheUseCase(
            chatListItemCacheRepository: chatListItemCacheRepository
        )
        
        let scheduledMeeting = ScheduledMeetingEntity(chatId: chatId)
        let result = await sut.avatar(for: scheduledMeeting)
        
        XCTAssertNil(result)
    }
    
    func testAvatar_forChatListItemAndCached_shouldReturnCachedAvatar() async {
        let chatId: HandleEntity = 100
        let chatListItemAvatar = ChatListItemAvatarEntity(
            primaryAvatarData: UIImage(systemName: "folder")?.pngData(),
            secondaryAvatarData: UIImage(systemName: "folder.fill")?.pngData()
        )
        let chatListItemCacheRepository = MockChatListItemCacheRepository(
            avatarCache: [chatId: chatListItemAvatar]
        )
        let sut = makeChatListItemCacheUseCase(
            chatListItemCacheRepository: chatListItemCacheRepository
        )
        
        let chatListItem = ChatListItemEntity(chatId: chatId)
        let result = await sut.avatar(for: chatListItem)
        
        XCTAssertEqual(result, chatListItemAvatar)
    }
    
    func testAvatar_forScheduledMeetingAndCached_shouldReturnCachedAvatar() async {
        let chatId: HandleEntity = 100
        let chatListItemAvatar = ChatListItemAvatarEntity(
            primaryAvatarData: UIImage(systemName: "folder")?.pngData(),
            secondaryAvatarData: UIImage(systemName: "folder.fill")?.pngData()
        )
        let chatListItemCacheRepository = MockChatListItemCacheRepository(
            avatarCache: [chatId: chatListItemAvatar]
        )
        let sut = makeChatListItemCacheUseCase(
            chatListItemCacheRepository: chatListItemCacheRepository
        )
        
        let scheduledMeeting = ScheduledMeetingEntity(chatId: chatId)
        let result = await sut.avatar(for: scheduledMeeting)
        
        XCTAssertEqual(result, chatListItemAvatar)
    }
    
    func testSetAvatar_forNewChatListItemAvatar_shouldMatch() async {
        let chatId: HandleEntity = 100
        let chatListItemAvatar = ChatListItemAvatarEntity(
            primaryAvatarData: UIImage(systemName: "folder")?.pngData(),
            secondaryAvatarData: UIImage(systemName: "folder.fill")?.pngData()
        )
        let chatListItemCacheRepository = MockChatListItemCacheRepository()
        let sut = makeChatListItemCacheUseCase(
            chatListItemCacheRepository: chatListItemCacheRepository
        )
        
        let chatRoom = ChatRoomEntity(chatId: chatId)
        await sut.setAvatar(chatListItemAvatar, for: chatRoom)
        
        let chatListItem = ChatListItemEntity(chatId: chatId)
        let result = await sut.avatar(for: chatListItem)
        XCTAssertEqual(result, chatListItemAvatar)
    }
    
    // MARK: - Private
    
    private func makeChatListItemCacheUseCase(
        chatListItemCacheRepository: some ChatListItemCacheRepositoryProtocol = MockChatListItemCacheRepository.newRepo
    ) -> some ChatListItemCacheUseCaseProtocol {
        ChatListItemCacheUseCase(repository: chatListItemCacheRepository)
    }
}
