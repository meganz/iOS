@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAPresentationMock
import MEGATest
import XCTest

final class ChatRoomParticipantsListViewModelTests: XCTestCase {
    func testInviteParticipants_onNotCall_shouldInviteParticipantsAndMatch() {
        let invitedUserId: [HandleEntity] = [1]
        var expectedInvitedUser = [HandleEntity]()
        let chatRoomUseCase = MockChatRoomUseCase(invitedToChat: { userId in
            expectedInvitedUser = [userId]
        })
        let sut = makeChatRoomParticipantsListViewModel(
            chatRoomUseCase: chatRoomUseCase
        )
        
        sut.inviteParticipants(invitedUserId)
        
        XCTAssertEqual(invitedUserId, expectedInvitedUser)
    }
    
    func testInviteParticipants_onCallAndWaitingRoomEnabledAndModerator_shouldCallAllowUsersJoinCallAndMatch() {
        let invitedUserId: [HandleEntity] = [1]
        let chatRoomUseCase = MockChatRoomUseCase()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isOpenInviteEnabled: false, isWaitingRoomEnabled: true)
        let sut = makeChatRoomParticipantsListViewModel(
            chatRoomUseCase: chatRoomUseCase,
            callUseCase: callUseCase,
            chatRoom: chatRoom
        )
        
        sut.inviteParticipants(invitedUserId)
        
        XCTAssertEqual(callUseCase.allowUsersJoinCall_CalledTimes, 1)
        XCTAssertEqual(callUseCase.allowedUsersJoinCall, invitedUserId)
    }
    
    func testInviteParticipants_onCallAndWaitingRoomEnabledAndOpenInviteEnabled_shouldCallAllowUsersJoinCallAndMatch() {
        let invitedUserId: [HandleEntity] = [1]
        let chatRoomUseCase = MockChatRoomUseCase()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let chatRoom = ChatRoomEntity(ownPrivilege: .standard, isOpenInviteEnabled: true, isWaitingRoomEnabled: true)
        let sut = makeChatRoomParticipantsListViewModel(
            chatRoomUseCase: chatRoomUseCase,
            callUseCase: callUseCase,
            chatRoom: chatRoom
        )
        
        sut.inviteParticipants(invitedUserId)
        
        XCTAssertEqual(callUseCase.allowUsersJoinCall_CalledTimes, 1)
        XCTAssertEqual(callUseCase.allowedUsersJoinCall, invitedUserId)
    }
    
    func testInviteParticipants_onCallAndNotWaitingRoomEnabledAndOpenInviteEnabled_shouldCallAllowUsersJoinCallAndMatch() {
        let invitedUserId: [HandleEntity] = [1]
        let chatRoomUseCase = MockChatRoomUseCase()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isOpenInviteEnabled: true, isWaitingRoomEnabled: false)
        let sut = makeChatRoomParticipantsListViewModel(
            chatRoomUseCase: chatRoomUseCase,
            callUseCase: callUseCase,
            chatRoom: chatRoom
        )
        
        sut.inviteParticipants(invitedUserId)
        
        XCTAssertEqual(callUseCase.allowUsersJoinCall_CalledTimes, 0)
    }
    
    func testInviteParticipants_onCallAndNotWaitingRoomEnabledAndModerator_shouldCallAllowUsersJoinCallAndMatch() {
        let invitedUserId: [HandleEntity] = [1]
        let chatRoomUseCase = MockChatRoomUseCase()
        let callUseCase = MockCallUseCase(call: CallEntity())
        let chatRoom = ChatRoomEntity(ownPrivilege: .moderator, isOpenInviteEnabled: false, isWaitingRoomEnabled: false)
        let sut = makeChatRoomParticipantsListViewModel(
            chatRoomUseCase: chatRoomUseCase,
            callUseCase: callUseCase,
            chatRoom: chatRoom
        )
        
        sut.inviteParticipants(invitedUserId)
        
        XCTAssertEqual(callUseCase.allowUsersJoinCall_CalledTimes, 0)
    }
    
    @MainActor
    func test_addParticipantTapped_tracked() async {
        let tracker = MockTracker()
        let sut = makeChatRoomParticipantsListViewModel(
            tracker: tracker
        )
        sut.addParticipantTapped()
        
        XCTAssertTrackedAnalyticsEventsEqual(
            tracker.trackedEventIdentifiers,
            [MeetingInfoAddParticipantButtonTappedEvent()]
        )
    }
    
    // MARK: - Private
    
    private func makeChatRoomParticipantsListViewModel(
        router: some MeetingInfoRouting = MockMeetingInfoRouter(),
        chatRoomUseCase: some ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol = MockChatRoomUserUseCase(),
        chatUseCase: some ChatUseCaseProtocol = MockChatUseCase(),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        callUseCase: some CallUseCaseProtocol = MockCallUseCase(),
        callUpdateUseCase: some CallUpdateUseCaseProtocol = MockCallUpdateUseCase(),
        chatRoom: ChatRoomEntity = ChatRoomEntity(),
        tracker: MockTracker = .init(),
        file: StaticString = #file,
        line: UInt = #line
    ) -> ChatRoomParticipantsListViewModel {
        let sut = ChatRoomParticipantsListViewModel(
            router: router,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            chatUseCase: chatUseCase,
            accountUseCase: accountUseCase,
            callUseCase: callUseCase,
            callUpdateUseCase: callUpdateUseCase,
            chatRoom: chatRoom,
            tracker: tracker
        )
        trackForMemoryLeaks(on: sut, file: file, line: line)
        return sut
    }
}
