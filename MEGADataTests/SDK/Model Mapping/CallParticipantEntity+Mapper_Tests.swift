import XCTest
@testable import MEGA
@testable import MEGADomain
import MEGADataMock

final class CallParticipantEntity_Mapper_Tests: XCTestCase {
    
    private func createChatSessionEntity(hasAudio: Bool = true, hasVideo: Bool = true) -> ChatSessionEntity {
        ChatSessionEntity(statusType: nil, termCode: .invalid, hasAudio: hasAudio, hasVideo: hasVideo, peerId: 1, clientId: 1, audioDetected: true, isOnHold: true, changes: 1, isHighResolution: true, isLowResolution: true, canReceiveVideoHiRes: true, canReceiveVideoLowRes:true)
    }
    
    private var sampleUsers: [MockUser] {
        [MockUser(handle: 1), MockUser(handle: 2), MockUser(handle: 3), MockUser(handle: 4), MockUser(handle: 5)]
    }
    
    func testInit_withNonModeratorParticipant() {
        let participant = CallParticipantEntity(session: createChatSessionEntity(), chatId: 100, sdk: MockSdk(myContacts: MockUserList()), chatSDK: MockChatSDK())
        XCTAssertFalse(participant.isModerator)
    }
    
    func testInit_withModeratorParticipant() {
        let chatRoom = MockChatRoom(peerPrivilage: .moderator)
        let chatSDK = MockChatSDK(chatRoom: chatRoom)
        let participant = CallParticipantEntity(session: createChatSessionEntity(), chatId: 100, sdk: MockSdk(myContacts: MockUserList()), chatSDK: chatSDK)
        XCTAssertTrue(participant.isModerator)
    }
    
    func testInit_withParticipantInContact() {
        let sdk = MockSdk(myContacts: MockUserList(users: sampleUsers))
        let chatRoom = MockChatRoom(peerPrivilage: .moderator)
        let chatSDK = MockChatSDK(chatRoom: chatRoom)
        let participant = CallParticipantEntity(session: createChatSessionEntity(), chatId: 100, sdk: sdk, chatSDK: chatSDK)
        XCTAssertTrue(participant.isInContactList)
    }
    
    func testInit_withParticipantNotInContact() {
        let sdk = MockSdk(myContacts: MockUserList(users: [MockUser(handle: 20)]))
        let chatRoom = MockChatRoom(peerPrivilage: .moderator)
        let chatSDK = MockChatSDK(chatRoom: chatRoom)
        let participant = CallParticipantEntity(session: createChatSessionEntity(), chatId: 100, sdk: sdk, chatSDK: chatSDK)
        XCTAssertFalse(participant.isInContactList)
    }
    
    func testInit_withParticipantVideoOn() {
        let sdk = MockSdk(myContacts: MockUserList(users: [MockUser(handle: 20)]))
        let chatRoom = MockChatRoom(peerPrivilage: .moderator)
        let chatSDK = MockChatSDK(chatRoom: chatRoom)
        let participant = CallParticipantEntity(session: createChatSessionEntity(), chatId: 100, sdk: sdk, chatSDK: chatSDK)
        XCTAssertTrue(participant.video == .on)
    }
    
    func testInit_withParticipantVideoOff() {
        let sdk = MockSdk(myContacts: MockUserList(users: [MockUser(handle: 20)]))
        let chatRoom = MockChatRoom(peerPrivilage: .moderator)
        let chatSDK = MockChatSDK(chatRoom: chatRoom)
        let participant = CallParticipantEntity(session: createChatSessionEntity(hasVideo: false), chatId: 100, sdk: sdk, chatSDK: chatSDK)
        XCTAssertTrue(participant.video == .off)

    }
    
    func testInit_withParticipantAudioOn() {
        let sdk = MockSdk(myContacts: MockUserList(users: [MockUser(handle: 20)]))
        let chatRoom = MockChatRoom(peerPrivilage: .moderator)
        let chatSDK = MockChatSDK(chatRoom: chatRoom)
        let participant = CallParticipantEntity(session: createChatSessionEntity(), chatId: 100, sdk: sdk, chatSDK: chatSDK)
        XCTAssertTrue(participant.audio == .on)
    }
    
    func testInit_withParticipantAudioOff() {
        let sdk = MockSdk(myContacts: MockUserList(users: [MockUser(handle: 20)]))
        let chatRoom = MockChatRoom(peerPrivilage: .moderator)
        let chatSDK = MockChatSDK(chatRoom: chatRoom)
        let participant = CallParticipantEntity(session: createChatSessionEntity(hasAudio: false), chatId: 100, sdk: sdk, chatSDK: chatSDK)
        XCTAssertTrue(participant.audio == .off)
    }
    
    func testMyselfFunc_withMyUserNotFound() {
        let sdk = MockSdk(myEmail: "my@email.com")
        let participant = CallParticipantEntity.myself(chatId: 1, sdk: sdk, chatSDK: MockChatSDK())
        XCTAssertNil(participant)
    }
    
    func testMyselfFunc_withMyEmailNotFound() {
        let sdk = MockSdk(myUser: MockUser(handle: 1))
        let participant = CallParticipantEntity.myself(chatId: 1, sdk: sdk, chatSDK: MockChatSDK())
        XCTAssertNil(participant)
    }
    
    func testMyselfFunc_withChatRoomNotFound() {
        let sdk = MockSdk(myUser: MockUser(handle: 1), myEmail: "my@email.com")
        let participant = CallParticipantEntity.myself(chatId: 1, sdk: sdk, chatSDK: MockChatSDK(chatRoom: nil))
        XCTAssertNil(participant)
    }
    
    func testMyselfFunc_withValidParticipant() {
        let sdk = MockSdk(myUser: MockUser(handle: 1), myEmail: "my@email.com")
        let participant = CallParticipantEntity.myself(chatId: 1, sdk: sdk, chatSDK: MockChatSDK())
        XCTAssertNotNil(participant)
    }
}
