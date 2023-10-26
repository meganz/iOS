import ChatRepo
import MEGADomain
import XCTest

final class ChatListItemCacheTests: XCTestCase {
    
    override func tearDown() async throws {
        try await super.tearDown()
        await ChatListItemCache.shared.removeAllCachedValues()
    }
    
    func testSetDescription_forNewChatListItemDescriptionEntity_shouldMatch() async {
        let sut = ChatListItemCache.shared
        
        let chatListItemDescription = ChatListItemDescriptionEntity(description: "Test Description")
        let handle: HandleEntity = 100
        await sut.setDescription(chatListItemDescription, for: handle)
        
        let result = await sut.description(for: handle)
        
        XCTAssertEqual(result, chatListItemDescription)
    }
    
    func testSetAvatar_forNewChatListItemAvatarEntity_shouldMatch() async {
        let sut = ChatListItemCache.shared
        
        let chatListItemAvatar = ChatListItemAvatarEntity(
            primaryAvatarData: UIImage(systemName: "folder")?.pngData(),
            secondaryAvatarData: UIImage(systemName: "folder.fill")?.pngData()
        )
        let handle: HandleEntity = 100
        await sut.setAvatar(chatListItemAvatar, for: handle)
        
        let result = await sut.avatar(for: handle)
        
        XCTAssertEqual(result, chatListItemAvatar)
    }
}
