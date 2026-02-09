import Foundation
import MEGADomain
import Testing

@Suite("PITAG Resolver Use Case Tests")
struct PitagResolverUseCaseTests {
    
    private let useCase = PitagResolverUseCase()
    
    @Test("Resolves multiple chats correctly")
    func testMultipleChatsTarget() {
        let chat1 = ChatListItemEntity(chatId: 1, group: false)
        let chat2 = ChatListItemEntity(chatId: 2, group: true)
        
        let target = useCase.resolvePitagTarget(forChats: [chat1, chat2], users: [])
        
        #expect(target == .multipleChats)
    }
    
    @Test("Resolves single user as 1-to-1 chat")
    func testSingleUserTarget() {
        let user = UserEntity(handle: 123)
        
        let target = useCase.resolvePitagTarget(forChats: [], users: [user])
        
        #expect(target == .chat1To1)
    }
    
    @Test("Resolves note to self correctly")
    func testNoteToSelfTarget() {
        let noteToSelfChat = ChatListItemEntity(chatId: 1, isNoteToSelf: true)
        
        let target = useCase.resolvePitagTarget(forChats: [noteToSelfChat], users: [])
        
        #expect(target == .noteToSelf)
    }
    
    @Test("Resolves group chat correctly")
    func testGroupChatTarget() {
        let groupChat = ChatListItemEntity(chatId: 1, group: true)
        
        let target = useCase.resolvePitagTarget(forChats: [groupChat], users: [])
        
        #expect(target == .chatGroup)
    }
    
    @Test("Resolves 1-to-1 chat correctly")
    func testOneToOneChatTarget() {
        let oneToOneChat = ChatListItemEntity(chatId: 1, group: false)
        
        let target = useCase.resolvePitagTarget(forChats: [oneToOneChat], users: [])
        
        #expect(target == .chat1To1)
    }
    
    @Test("Returns not applicable when no recipients")
    func testNotApplicableTarget() {
        let target = useCase.resolvePitagTarget(forChats: [], users: [])
        
        #expect(target == .notApplicable)
    }
    
    @Test("Resolves multiple users and chats as multiple chats")
    func testMultipleUsersAndChats() {
        let chat = ChatListItemEntity(chatId: 1, group: false)
        let user = UserEntity(handle: 123)
        
        let target = useCase.resolvePitagTarget(forChats: [chat], users: [user])
        
        #expect(target == .multipleChats)
    }
}
