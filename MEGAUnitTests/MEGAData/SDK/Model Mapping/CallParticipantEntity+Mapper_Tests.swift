import XCTest
@testable import MEGA

final class CallParticipantEntity_Mapper_Tests: XCTestCase {
    
    private func createChatSessionEntity(hasAudio: Bool = true, hasVideo: Bool = true) -> ChatSessionEntity {
        ChatSessionEntity(statusType: nil, hasAudio: hasAudio, hasVideo: hasVideo, peerId: 1, clientId: 1, audioDetected: true, isOnHold: true, changes: 1, isHighResolution: true, isLowResolution: true, canReceiveVideoHiRes: true, canReceiveVideoLowRes:true)
    }
    
    private var sampleUsers: [MockUser] {
        [MockUser(handle: 1), MockUser(handle: 2), MockUser(handle: 3), MockUser(handle: 4), MockUser(handle: 5)]
    }
    
    func testInit_withNonModeratorParticipant() {
        let participant = CallParticipantEntity(session: createChatSessionEntity(), chatId: 100, sdk: MockSDK(), chatSDK: MockChatSDK())
        XCTAssertFalse(participant.isModerator)
    }
    
    func testInit_withModeratorParticipant() {
        let chatRoom = MockChatRoom(peerPrivilage: .moderator)
        let chatSDK = MockChatSDK(chatRoom: chatRoom)
        let participant = CallParticipantEntity(session: createChatSessionEntity(), chatId: 100, sdk: MockSDK(), chatSDK: chatSDK)
        XCTAssertTrue(participant.isModerator)
    }
    
    func testInit_withParticipantInContact() {
        let sdk = MockSDK(userList: MockUserList(users: sampleUsers))
        let chatRoom = MockChatRoom(peerPrivilage: .moderator)
        let chatSDK = MockChatSDK(chatRoom: chatRoom)
        let participant = CallParticipantEntity(session: createChatSessionEntity(), chatId: 100, sdk: sdk, chatSDK: chatSDK)
        XCTAssertTrue(participant.isInContactList)
    }
    
    func testInit_withParticipantNotInContact() {
        let sdk = MockSDK(userList: MockUserList(users: [MockUser(handle: 20)]))
        let chatRoom = MockChatRoom(peerPrivilage: .moderator)
        let chatSDK = MockChatSDK(chatRoom: chatRoom)
        let participant = CallParticipantEntity(session: createChatSessionEntity(), chatId: 100, sdk: sdk, chatSDK: chatSDK)
        XCTAssertFalse(participant.isInContactList)
    }
    
    func testInit_withParticipantVideoOn() {
        let sdk = MockSDK(userList: MockUserList(users: [MockUser(handle: 20)]))
        let chatRoom = MockChatRoom(peerPrivilage: .moderator)
        let chatSDK = MockChatSDK(chatRoom: chatRoom)
        let participant = CallParticipantEntity(session: createChatSessionEntity(), chatId: 100, sdk: sdk, chatSDK: chatSDK)
        XCTAssertTrue(participant.video == .on)
    }
    
    func testInit_withParticipantVideoOff() {
        let sdk = MockSDK(userList: MockUserList(users: [MockUser(handle: 20)]))
        let chatRoom = MockChatRoom(peerPrivilage: .moderator)
        let chatSDK = MockChatSDK(chatRoom: chatRoom)
        let participant = CallParticipantEntity(session: createChatSessionEntity(hasVideo: false), chatId: 100, sdk: sdk, chatSDK: chatSDK)
        XCTAssertTrue(participant.video == .off)

    }
    
    func testInit_withParticipantAudioOn() {
        let sdk = MockSDK(userList: MockUserList(users: [MockUser(handle: 20)]))
        let chatRoom = MockChatRoom(peerPrivilage: .moderator)
        let chatSDK = MockChatSDK(chatRoom: chatRoom)
        let participant = CallParticipantEntity(session: createChatSessionEntity(), chatId: 100, sdk: sdk, chatSDK: chatSDK)
        XCTAssertTrue(participant.audio == .on)
    }
    
    func testInit_withParticipantAudioOff() {
        let sdk = MockSDK(userList: MockUserList(users: [MockUser(handle: 20)]))
        let chatRoom = MockChatRoom(peerPrivilage: .moderator)
        let chatSDK = MockChatSDK(chatRoom: chatRoom)
        let participant = CallParticipantEntity(session: createChatSessionEntity(hasAudio: false), chatId: 100, sdk: sdk, chatSDK: chatSDK)
        XCTAssertTrue(participant.audio == .off)
    }
    
    func testMyselfFunc_withMyUserNotFound() {
        let sdk = MockSDK(myEmail: "my@email.com")
        let participant = CallParticipantEntity.myself(chatId: 1, sdk: sdk, chatSDK: MockChatSDK())
        XCTAssertNil(participant)
    }
    
    func testMyselfFunc_withMyEmailNotFound() {
        let sdk = MockSDK(myUser: MockUser(handle: 1))
        let participant = CallParticipantEntity.myself(chatId: 1, sdk: sdk, chatSDK: MockChatSDK())
        XCTAssertNil(participant)
    }
    
    func testMyselfFunc_withChatRoomNotFound() {
        let sdk = MockSDK(myUser: MockUser(handle: 1), myEmail: "my@email.com")
        let participant = CallParticipantEntity.myself(chatId: 1, sdk: sdk, chatSDK: MockChatSDK(chatRoom: nil))
        XCTAssertNil(participant)
    }
    
    func testMyselfFunc_withValidParticipant() {
        let sdk = MockSDK(myUser: MockUser(handle: 1), myEmail: "my@email.com")
        let participant = CallParticipantEntity.myself(chatId: 1, sdk: sdk, chatSDK: MockChatSDK())
        XCTAssertNotNil(participant)
    }
}

final fileprivate class MockSDK: MEGASdk {
    private let userList: MEGAUserList
    private let _myUser: MEGAUser?
    private let _myEmail: String?
    
    init(userList: MEGAUserList = MockUserList(), myUser: MEGAUser? = nil, myEmail: String? = nil) {
        self.userList = userList
        _myUser = myUser
        _myEmail = myEmail
        super.init()
    }
    
    override func contacts() -> MEGAUserList {
        userList
    }
    
    override var myUser: MEGAUser? {
        _myUser
    }
    
    override var myEmail: String? {
        _myEmail
    }
}

final fileprivate class MockUserList: MEGAUserList {
    private let users: [MEGAUser]
    
    init(users: [MEGAUser] = []) {
        self.users = users
        super.init()
    }
    
    override var size: NSNumber! {
        NSNumber(integerLiteral: users.count)
    }
    
    override func user(at index: Int) -> MEGAUser! {
        users[index]
    }
}

final fileprivate class MockUser: MEGAUser {
    private let _handle: MEGAHandle
    private let _visibility: MEGAUserVisibility
    
    init(handle: MEGAHandle = 0, visibility: MEGAUserVisibility = .visible) {
        _handle = handle
        _visibility = visibility
        super.init()
    }
    
    override var handle: MEGAHandle {
        _handle
    }
    
    override var visibility: MEGAUserVisibility {
        _visibility
    }
}

final fileprivate class MockChatSDK: MEGAChatSdk {
    private let chatRoom: MEGAChatRoom?
    
    init(chatRoom: MEGAChatRoom? = MockChatRoom()) {
        self.chatRoom = chatRoom
        super.init()
    }
    
    override func chatRoom(forChatId chatId: MEGAHandle) -> MEGAChatRoom? {
        chatRoom
    }
}

final fileprivate class MockChatRoom: MEGAChatRoom {
    private let peerPrivilage: MEGAChatRoomPrivilege
    
    init(peerPrivilage: MEGAChatRoomPrivilege = .unknown) {
        self.peerPrivilage = peerPrivilage
        super.init()
    }
    
    override func peerPrivilege(byHandle userHande: MEGAHandle) -> Int {
        peerPrivilage.rawValue
    }
    
    override var authorizationToken: String {
        ""
    }
}




