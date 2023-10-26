import ChatRepo
import ChatRepoMock
import MEGADomain
import MEGADomainMock
import XCTest

final class ChatListItemCacheRepositoryTests: XCTestCase {
    func testDescription_notCached_shouldReturnNil() async {
        let chatId: HandleEntity = 100
        let chatListItemCache = MockChatListItemCache()
        let sut = makeChatListItemCacheRepository(
            chatListItemCache: chatListItemCache
        )
        
        let chatListItem = ChatListItemEntity(chatId: chatId)
        let result = await sut.description(for: chatListItem)
        
        XCTAssertNil(result)
    }
    
    func testDescription_cached_shouldReturnCachedDescription() async {
        let chatId: HandleEntity = 100
        let chatListItemDescription = ChatListItemDescriptionEntity(description: "Test Description")
        let chatListItemCache = MockChatListItemCache(descriptionCache: [chatId: chatListItemDescription])
        let sut = makeChatListItemCacheRepository(
            chatListItemCache: chatListItemCache
        )
        
        let chatListItem = ChatListItemEntity(chatId: chatId)
        let result = await sut.description(for: chatListItem)
        
        XCTAssertEqual(result, chatListItemDescription)
    }
    
    func testSetDescription_forNewChatListItemDescriptionEntity_shouldMatch() async {
        
        let sut = makeChatListItemCacheRepository()
        
        let chatListItemDescription = ChatListItemDescriptionEntity(description: "Test Description")
        let chatId: HandleEntity = 100
        let chatListItem = ChatListItemEntity(chatId: chatId)
        await sut.setDescription(chatListItemDescription, for: chatListItem)
        
        let result = await sut.description(for: chatListItem)
        
        XCTAssertEqual(result, chatListItemDescription)
    }
    
    func testAvatar_forChatListItemAndNotCached_shouldReturnNil() async {
        let chatId: HandleEntity = 100
        let chatListItemCache = MockChatListItemCache()
        let sut = makeChatListItemCacheRepository(
            chatListItemCache: chatListItemCache
        )
        
        let chatListItem = ChatListItemEntity(chatId: chatId)
        let result = await sut.avatar(for: chatListItem)
        
        XCTAssertNil(result)
    }
    
    func testAvatar_forScheduledMeetingAndNotCached_shouldReturnNil() async {
        let chatId: HandleEntity = 100
        let chatListItemCache = MockChatListItemCache()
        let sut = makeChatListItemCacheRepository(
            chatListItemCache: chatListItemCache
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
        let chatListItemCache = MockChatListItemCache(
            avatarCache: [chatId: chatListItemAvatar]
        )
        let sut = makeChatListItemCacheRepository(
            chatListItemCache: chatListItemCache
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
        let chatListItemCache = MockChatListItemCache(
            avatarCache: [chatId: chatListItemAvatar]
        )
        let sut = makeChatListItemCacheRepository(
            chatListItemCache: chatListItemCache
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
        let chatListItemCache = MockChatListItemCache()
        let sut = makeChatListItemCacheRepository(
            chatListItemCache: chatListItemCache
        )
        
        let chatRoom = ChatRoomEntity(chatId: chatId)
        await sut.setAvatar(chatListItemAvatar, for: chatRoom)
        
        let chatListItem = ChatListItemEntity(chatId: chatId)
        let result = await sut.avatar(for: chatListItem)
        XCTAssertEqual(result, chatListItemAvatar)
    }
    
    // MARK: - Private
    
    private func makeChatListItemCacheRepository(
        chatListItemCache: some ChatListItemCacheProtocol = MockChatListItemCache()
    ) -> ChatListItemCacheRepository {
        ChatListItemCacheRepository(
            chatListItemCache: chatListItemCache
        )
    }
}
