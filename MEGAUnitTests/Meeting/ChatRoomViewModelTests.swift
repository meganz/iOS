@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPermissions
import MEGAPermissionsMock
import XCTest

final class ChatRoomViewModelTests: XCTestCase {
    
    func test_scheduledMeetingManagementMessage_meetingUpdatedMyself() async throws {
        let chatListItemEntity = ChatListItemEntity(lastMessageType: .scheduledMeeting, lastMessageSender: 1001)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(), message: ChatMessageEntity())
        let userUseCase = MockAccountUseCase(currentUser: UserEntity(handle: 1001))
        let viewModel = ChatRoomViewModel(chatListItem: chatListItemEntity,
                                          chatRoomUseCase: chatRoomUseCase,
                                          accountUseCase: userUseCase,
                                          scheduledMeetingUseCase: MockScheduledMeetingUseCase())
        try await viewModel.updateDescription()
        XCTAssertTrue(viewModel.description == Strings.Localizable.Meetings.Scheduled.ManagementMessages.updated("Me"))
    }
    
    func test_scheduledMeetingManagementMessage_meetingUpdatedByOthers() async throws {
        let chatListItemEntity = ChatListItemEntity(lastMessageType: .scheduledMeeting, lastMessageSender: 1002)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(), message: ChatMessageEntity())
        let userUseCase = MockChatRoomUserUseCase(userDisplayNamesForPeersResult: .success([(handle: 1002, name: "Bob")]))
        let viewModel = ChatRoomViewModel(chatListItem: chatListItemEntity,
                                          chatRoomUseCase: chatRoomUseCase,
                                          chatRoomUserUseCase: userUseCase,
                                          scheduledMeetingUseCase: MockScheduledMeetingUseCase())
        try await viewModel.updateDescription()
        XCTAssertTrue(viewModel.description == Strings.Localizable.Meetings.Scheduled.ManagementMessages.updated("Bob"))
    }
    
    func testStartOrJoinCall_isModeratorAndWaitingRoomEnabledAndCallNotActive_shouldStartCall() {
        let router = MockChatRoomsListRouter()
        let chatUseCase = MockChatUseCase(isCallActive: false)
        let callUseCase = MockCallUseCase(callCompletion: .success(CallEntity()))
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator))

        let sut = ChatRoomViewModel(router: router, chatRoomUseCase: chatRoomUseCase, chatUseCase: chatUseCase, callUseCase: callUseCase)

        sut.startOrJoinCall()
        
        XCTAssertTrue(router.openCallView_calledTimes == 1)
    }
    
    func testStartOrJoinCall_isModeratorAndWaitingRoomEnabledAndCallActive_shouldJoinCall() {
        let router = MockChatRoomsListRouter()
        let chatUseCase = MockChatUseCase(isCallActive: true)
        let callUseCase = MockCallUseCase(callCompletion: .success(CallEntity()))
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator))

        let sut = ChatRoomViewModel(router: router, chatRoomUseCase: chatRoomUseCase, chatUseCase: chatUseCase, callUseCase: callUseCase)

        sut.startOrJoinCall()
        
        XCTAssertTrue(router.openCallView_calledTimes == 1)
    }
    
    func testStartOrJoinMeetingTapped_onExistsActiveCall_shouldPresentMeetingAlreadyExists() {
        let router = MockChatRoomsListRouter()
        let chatUseCase = MockChatUseCase(isExistingActiveCall: true)
        let sut = ChatRoomViewModel(router: router, chatUseCase: chatUseCase)
        
        sut.startOrJoinMeetingTapped()
        
        XCTAssertTrue(router.presentMeetingAlreadyExists_calledTimes == 1)
    }
    
    func testStartOrJoinMeetingTapped_onNoActiveCallAndShouldOpenWaitRoom_shouldPresentWaitingRoom() {
        let router = MockChatRoomsListRouter()
        let chatRoomUseCase = MockChatRoomUseCase(shouldOpenWaitRoom: true)
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase(scheduledMeetingsList: [ScheduledMeetingEntity()])
        let featureFlagProvider = MockFeatureFlagProvider(list: [.waitingRoom: true])
        let sut = ChatRoomViewModel(router: router, chatRoomUseCase: chatRoomUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase, featureFlagProvider: featureFlagProvider)
        
        sut.startOrJoinMeetingTapped()
        
        XCTAssertTrue(router.presentWaitingRoom_calledTimes == 1)
    }
    
}
