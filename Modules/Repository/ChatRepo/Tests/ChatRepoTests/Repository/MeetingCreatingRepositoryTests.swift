import ChatRepo
import ChatRepoMock
import MEGAChatSdk
import MEGADomain
import MEGASDKRepoMock
import MEGATest
import XCTest

final class MeetingCreatingRepositoryTests: XCTestCase {
    private let createMeetingNowEntity = CreateMeetingNowEntity(
        meetingName: "meetingName",
        speakRequest: true,
        waitingRoom: true,
        allowNonHostToAddParticipants: true
    )
    
    private let chatId: ChatIdEntity = 1
    private let userHandle: HandleEntity = 1
    private let link = "publicLinkChat"
    private let firstname = "firstname"
    private let lastname = "lastname"
    
    func testUserEmail_shouldMatch() {
        let myEmail = "test@mega.nz"
        let sut = makeSUT(myEmail: myEmail)
        
        XCTAssertEqual(sut.userEmail, myEmail)
    }
    
    func testCreateMeeting_ifRequestSuccess_returnAChatRoom() async throws {
        let sut = makeSUT(MockChatRoom())
        
        let chatRoomEntity = try await sut.createMeeting(createMeetingNowEntity)
        
        XCTAssertNotNil(chatRoomEntity)
    }
    
    func testCreateMeeting_ifRequestFails_shouldThrowError() async throws {
        let sut = makeSUT(chatError: .MEGAChatErrorTypeNoEnt)
        await XCTAsyncAssertThrowsError(try await sut.createMeeting(createMeetingNowEntity)) { errorThrown in
            XCTAssertEqual(errorThrown as? CallErrorEntity, .generic)
        }
    }
    
    func testCreateMeeting_ifRequestSuccess_andChatRoomIsNil_shouldThrowError() async throws {
        let sut = makeSUT()
        await XCTAsyncAssertThrowsError(try await sut.createMeeting(createMeetingNowEntity)) { errorThrown in
            XCTAssertEqual(errorThrown as? CallErrorEntity, .generic)
        }
    }
    
    func testJoinChat_ifRequestSuccess_returnAChatRoom() async throws {
        let sut = makeSUT(MockChatRoom())
        
        let chatRoomEntity = try await sut.joinChat(forChatId: chatId, userHandle: userHandle)
        
        XCTAssertNotNil(chatRoomEntity)
    }
    
    func testJoinChat_ifRequestFails_shouldThrowError() async throws {
        let sut = makeSUT(chatError: .MEGAChatErrorTypeNoEnt)
        await XCTAsyncAssertThrowsError(try await sut.joinChat(forChatId: chatId, userHandle: userHandle)) { errorThrown in
            XCTAssertNotNil(errorThrown)
        }
    }
    
    func testJoinChat_ifRequestSuccess_andChatRoomIsNil_shouldThrowError() async throws {
        let sut = makeSUT()
        await XCTAsyncAssertThrowsError(try await sut.joinChat(forChatId: chatId, userHandle: userHandle)) { errorThrown in
            XCTAssertNotNil(errorThrown)
        }
    }
    
    func testCheckChatLink_ifRequestSuccess_returnAChatRoom() async throws {
        let sut = makeSUT(MockChatRoom())
        
        let chatRoomEntity = try await sut.checkChatLink(link: link)
        
        XCTAssertNotNil(chatRoomEntity)
    }
    
    func testCheckChatLink_ifRequestFails_shouldThrowError() async throws {
        let sut = makeSUT(chatError: .MEGAChatErrorTypeNoEnt)
        await XCTAsyncAssertThrowsError(try await sut.checkChatLink(link: link)) { errorThrown in
            XCTAssertNotNil(errorThrown)
        }
    }
    
    func testCheckChatLink_ifRequestSuccess_andChatRoomIsNil_shouldThrowError() async throws {
        let sut = makeSUT()
        await XCTAsyncAssertThrowsError(try await sut.checkChatLink(link: link)) { errorThrown in
            XCTAssertNotNil(errorThrown)
        }
    }
    
    func testCreateEphemeralAccountAndJounChat_ifSomeRequestFails_shouldThrowError() async throws {
        let sut = makeSUT(chatError: .MEGAChatErrorTypeNoEnt)
        await XCTAsyncAssertThrowsError(try await sut.createEphemeralAccountAndJoinChat(firstName: firstname, lastName: lastname, link: link)) { errorThrown in
            XCTAssertNotNil(errorThrown)
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(
        _ chatRoom: MEGAChatRoom? = nil,
        myEmail: String? = nil,
        chatError: MEGAChatErrorType = .MEGAChatErrorTypeOk,
        createMeetingNowEntity: CreateMeetingNowEntity? = nil
    ) -> MeetingCreatingRepository {
        let chatSDK = MockChatSDK(
            chatRoom: chatRoom,
            chatError: chatError,
            chatRequest: MockChatRequest()
        )
        let sdk = MockSdk(myEmail: myEmail)
        let sut = MeetingCreatingRepository(
            chatSdk: chatSDK,
            sdk: sdk,
            chatConnectionStateUpdateProvider: ChatUpdatesProvider(sdk: chatSDK)
        )
        
        trackForMemoryLeaks(on: sut)
        
        return sut
    }
}
