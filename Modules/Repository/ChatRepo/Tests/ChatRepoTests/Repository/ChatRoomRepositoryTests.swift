import ChatRepo
import ChatRepoMock
import MEGAChatSdk
import MEGADomain
import MEGATest
import XCTest

final class ChatRoomRepositoryTests: XCTestCase {
    private let chatRoom = MockChatRoom().toChatRoomEntity()
    private let chatId: ChatIdEntity = 1
    private let userHandle: HandleEntity = 1
    private let newTitle = "New Chat Room Title"
    private let link = "publicLinkChat"
    
    func testUpdateChatPrivilege_forNewPrivilegeModerator_ifRequestSuccess_shouldUpdateToModerator() async throws {
        let sut = makeSUT()

        let privilege = try await sut.updateChatPrivilege(chatRoom: chatRoom, userHandle: 1, privilege: .moderator)
        
        XCTAssertEqual(privilege, .moderator)
    }
    
    func testUpdateChatPrivilege_forNewPrivilegeModerator_ifRequestFails_shouldThrowAnError() async throws {
        let sut = makeSUT(chatError: .MEGAChatErrorTypeNoEnt)
        await expectError { try await sut.updateChatPrivilege(chatRoom: MockChatRoom().toChatRoomEntity(), userHandle: 1, privilege: .moderator) }
    }
    
    func testChatRoomForChatId_ifChatRoomExists_shouldReturnChatroom() {
        let sut = makeSUT(MockChatRoom())
        
        let chatRoom = sut.chatRoom(forChatId: chatId)
        
        XCTAssertEqual(chatRoom?.chatId, chatId)
    }
    
    func testChatRoomForChatId_ifChatRoomDoesNotExist_shouldReturnNil() {
        let sut = makeSUT()
        
        let chatRoom = sut.chatRoom(forChatId: chatId)
        
        XCTAssertNil(chatRoom, "Chatroom should be nil")
    }
    
    func testChatRoomForUserHandle_ifChatRoomExists_shouldReturnChatroom() {
        let sut = makeSUT(MockChatRoom())
        
        let chatRoom = sut.chatRoom(forUserHandle: userHandle)
        
        XCTAssertEqual(chatRoom?.chatId, userHandle)
    }
    
    func testChatRoomForUserHandle_ifChatRoomDoesNotExist_shouldReturnNil() {
        let sut = makeSUT()
        
        let chatRoom = sut.chatRoom(forUserHandle: userHandle)
        
        XCTAssertNil(chatRoom, "Chatroom should be nil")
    }
    
    func testUserStatus_forUserHandle_shouldReturnCorrectStatus() {
        let sut = makeSUT(userStatus: [1: .online])
        
        let status = sut.userStatus(forUserHandle: userHandle)
        
        XCTAssertEqual(status, MEGAChatStatus.online.toChatStatusEntity())
        
    }
    
    func testRenameChatRoom_ifSuccess_shouldReturnUpdatedTitle() async throws {
        let newTitle = "New Chat Room Title"
        let sut = makeSUT(text: newTitle)
        
        let updatedTitle = try await sut.renameChatRoom(chatRoom, title: newTitle)
        
        XCTAssertEqual(updatedTitle, newTitle)
    }
    
    func testRenameChatRoom_textIsNil_shouldThrowAnError() async throws {
        let sut = makeSUT()
        await expectError { try await sut.renameChatRoom(chatRoom, title: newTitle) }
    }
    
    func testRenameChatRoom_ifFail_shouldThrowAnError() async throws {
        let sut = makeSUT(chatError: .MEGAChatErrorTypeNoEnt)
        await expectError { try await sut.renameChatRoom(chatRoom, title: newTitle) }
    }
    
    func testArchiveChatRoom_ifRequestSuccess_shouldReturnTrue() async throws {
        let sut = makeSUT()
        
        let isArchived = try await sut.archive(true, chatRoom: chatRoom)
        
        XCTAssertTrue(isArchived)
    }
    
    func testArchiveChatRoom_ifRequestFail_shouldThrowAnError() async throws {
        let sut = makeSUT(chatError: .MEGAChatErrorTypeNoEnt)
        await expectError { try await sut.archive(true, chatRoom: chatRoom) }
    }
    
    func testAllowNonHostToAddParticipants_ifRequestSuccess_shouldReturnTrue() async throws {
        let sut = makeSUT()
        
        let isAllowed = try await sut.allowNonHostToAddParticipants(true, forChatRoom: chatRoom)
        
        XCTAssertTrue(isAllowed)
    }
    
    func testAllowNonHostToAddParticipants_ifRequestFails_shouldThrowAnError() async throws {
        let sut = makeSUT(chatError: .MEGAChatErrorTypeNoEnt)
        await expectError { try await sut.allowNonHostToAddParticipants(true, forChatRoom: chatRoom) }
    }
    
    func testWaitingRoom_ifRequestSuccess_shouldReturnTrue() async throws {
        let sut = makeSUT()
        
        let isEnabled = try await sut.waitingRoom(true, forChatRoom: chatRoom)
        
        XCTAssertTrue(isEnabled)
    }
    
    func testWaitingRoom_ifRequestFails_shouldThrowAnError() async throws {
        let sut = makeSUT(chatError: .MEGAChatErrorTypeNoEnt)
        await expectError { try await sut.waitingRoom(true, forChatRoom: chatRoom) }
    }
    
    func testLeaveChatRoom_ifRequestSuccess_shouldReturnTrue() async throws {
        let sut = makeSUT()
        
        let hasLeft = await sut.leaveChatRoom(chatRoom: chatRoom)
        
        XCTAssertTrue(hasLeft)
    }
    
    func testLeaveChatRoom_ifRequestFails_shouldReturnFalse() async throws {
        let sut = makeSUT(chatError: .MEGAChatErrorTypeNoEnt)
        
        let hasLeft = await sut.leaveChatRoom(chatRoom: chatRoom)
        
        XCTAssertFalse(hasLeft)
    }
    
    func testUserEmail_whenContactEmailExists_shouldReturnNonNil() async throws {
        let sut = makeSUT(emailByHandle: [1: "test@mega.nz"])
        
        let userHandle: HandleEntity = 1
        let email = await sut.userEmail(for: userHandle)
        
        XCTAssertNotNil(email, "Emails should not be nil")
    }
    
    func testUserEmail_whenContactEmailDoesnotExists_andRequestSuccess_shouldReturnNonNil() async throws {
        let email = "test@mega.nz"
        let sut = makeSUT(text: email)
        
        let userHandle: HandleEntity = 1
        let userEmail = await sut.userEmail(for: userHandle)
        
        XCTAssertEqual(email, userEmail)
    }
    
    func testUserEmail_whenContactEmailDoesnotExists_andRequestFail_shouldReturnNil() async throws {
        let sut = makeSUT(chatError: .MEGAChatErrorTypeNoEnt)
        
        let userHandle: HandleEntity = 1
        let email = await sut.userEmail(for: userHandle)
        
        XCTAssertNil(email, "Emails should be nil")
    }
    
    func testCreatePublicLink_whenTextIsNotNil_shouldReturnTheText() async throws {
        let sut = makeSUT(text: link)
        
        let publicLink = try await sut.createPublicLink(forChatRoom: chatRoom)
        
        XCTAssertEqual(link, publicLink)
    }
    
    func testCreatePublicLink_whenTextIsNil_shouldThrowResourceNotFound() async throws {
        let sut = makeSUT()
        await expectError { try await sut.createPublicLink(forChatRoom: chatRoom) }
    }
    
    func testCreatePublicLink_whenRequestFails_shouldThrowAnError() async throws {
        let sut = makeSUT(chatError: .MEGAChatErrorTypeNoEnt)
        await expectError { try await sut.createPublicLink(forChatRoom: chatRoom) }
    }
    
    func testQueryPublicLink_whenTextIsNotNil_shouldReturnTheLink() async throws {
        let sut = makeSUT(text: link)
        
        let publicLink = try await sut.queryChatLink(forChatRoom: chatRoom)
        
        XCTAssertEqual(link, publicLink)
    }
    
    func testQueryPublicLink_whenTextIsNil_shouldThrowResourceNotFound() async throws {
        let sut = makeSUT()
        await expectError { try await sut.queryChatLink(forChatRoom: chatRoom) }
    }
    
    func testQueryPublicLink_whenRequestFails_shouldThrowAnError() async throws {
        let sut = makeSUT(chatError: .MEGAChatErrorTypeNoEnt)
        await expectError { try await sut.queryChatLink(forChatRoom: chatRoom) }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        _ chatRoom: MEGAChatRoom? = nil,
        text: String? = nil,
        chatError: MEGAChatErrorType = .MEGAChatErrorTypeOk,
        emailByHandle: [UInt64: String] = [:],
        userStatus: [UInt64: MEGAChatStatus] =  [:]
    ) -> ChatRoomRepository {
        let chatSDK = MockChatSDK(
            chatRoom: chatRoom,
            emailByHandle: emailByHandle,
            userStatus: userStatus,
            chatError: chatError,
            chatRequest: MockChatRequest(text: text)
        )
        let sut = ChatRoomRepository(
            sdk: chatSDK,
            chatUpdatesProvider: ChatUpdatesProvider(sdk: chatSDK)
        )
        
        trackForMemoryLeaks(on: sut)
        
        return sut
    }
    
    private func expectError<T>(from function: () async throws -> T, file: StaticString = #filePath, line: UInt = #line) async {
        do {
            _ = try await function()
            XCTFail("Expected an error to be thrown", file: file, line: line)
        } catch {
            XCTAssertNotNil(error, file: file, line: line)
        }
    }
}
