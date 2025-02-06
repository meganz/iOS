@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAL10n
import MEGAPermissions
import MEGAPermissionsMock
import MEGAPresentationMock
import XCTest

final class ChatRoomViewModelTests: XCTestCase {
    
    @MainActor
    func test_scheduledMeetingManagementMessage_meetingUpdatedMyself() async throws {
        let chatListItemEntity = ChatListItemEntity(lastMessageType: .scheduledMeeting, lastMessageSender: 1001)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(), message: ChatMessageEntity())
        let userUseCase = MockAccountUseCase(currentUser: UserEntity(handle: 1001))
        let viewModel = ChatRoomViewModelFactory.make(chatListItem: chatListItemEntity,
                                          chatRoomUseCase: chatRoomUseCase,
                                          accountUseCase: userUseCase,
                                          scheduledMeetingUseCase: MockScheduledMeetingUseCase())
        try await viewModel.updateDescription()
        XCTAssertTrue(viewModel.description == Strings.Localizable.Meetings.Scheduled.ManagementMessages.updated("Me"))
    }
    
    @MainActor
    func test_scheduledMeetingManagementMessage_meetingUpdatedByOthers() async throws {
        let chatListItemEntity = ChatListItemEntity(lastMessageType: .scheduledMeeting, lastMessageSender: 1002)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(), message: ChatMessageEntity())
        let userUseCase = MockChatRoomUserUseCase(userDisplayNamesForPeersResult: .success([(handle: 1002, name: "Bob")]))
        let viewModel = ChatRoomViewModelFactory.make(chatListItem: chatListItemEntity,
                                          chatRoomUseCase: chatRoomUseCase,
                                          chatRoomUserUseCase: userUseCase,
                                          scheduledMeetingUseCase: MockScheduledMeetingUseCase())
        try await viewModel.updateDescription()
        XCTAssertTrue(viewModel.description == Strings.Localizable.Meetings.Scheduled.ManagementMessages.updated("Bob"))
    }
    
    @MainActor
    func testStartOrJoinCall_isModeratorAndWaitingRoomEnabledAndCallNotActive_shouldStartCall() {
        let router = MockChatRoomsListRouter()
        let chatUseCase = MockChatUseCase(isCallActive: false)
        let callUseCase = MockCallUseCase(callCompletion: .success(CallEntity()))
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator))

        let sut = ChatRoomViewModelFactory.make(router: router, chatRoomUseCase: chatRoomUseCase, chatUseCase: chatUseCase, callUseCase: callUseCase)

        sut.startOrJoinCall()
        
        XCTAssertTrue(router.openCallView_calledTimes == 1)
    }
    
    @MainActor
    func testStartOrJoinCall_isModeratorAndWaitingRoomEnabledAndCallActive_shouldJoinCall() {
        let router = MockChatRoomsListRouter()
        let chatUseCase = MockChatUseCase(isCallActive: true)
        let callUseCase = MockCallUseCase(callCompletion: .success(CallEntity()))
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator))

        let sut = ChatRoomViewModelFactory.make(router: router, chatRoomUseCase: chatRoomUseCase, chatUseCase: chatUseCase, callUseCase: callUseCase)

        sut.startOrJoinCall()
        
        XCTAssertTrue(router.openCallView_calledTimes == 1)
    }
    
    @MainActor
    func testStartOrJoinCall_callNotExists_startCallCalled() {
        let callController = MockCallController()
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(ownPrivilege: .moderator))
        let sut = ChatRoomViewModelFactory.make(chatRoomUseCase: chatRoomUseCase, callController: callController, callUseCase: MockCallUseCase(call: nil))

        sut.startOrJoinCall()
        
        XCTAssertTrue(callController.startCall_CalledTimes == 1)
    }
    
    @MainActor
    func testStartOrJoinMeetingTapped_onExistsActiveCall_shouldPresentMeetingAlreadyExists() {
        let router = MockChatRoomsListRouter()
        let chatUseCase = MockChatUseCase(isExistingActiveCall: true)
        let sut = ChatRoomViewModelFactory.make(router: router, chatUseCase: chatUseCase)
        
        sut.startOrJoinMeetingTapped()
        
        XCTAssertTrue(router.presentMeetingAlreadyExists_calledTimes == 1)
    }
    
    @MainActor
    func testStartOrJoinMeetingTapped_onNoActiveCallAndShouldOpenWaitRoom_shouldPresentWaitingRoom() {
        let router = MockChatRoomsListRouter()
        let chatRoomUseCase = MockChatRoomUseCase(shouldOpenWaitRoom: true)
        let scheduledMeetingUseCase = MockScheduledMeetingUseCase(scheduledMeetingsList: [ScheduledMeetingEntity()])
        let sut = ChatRoomViewModelFactory.make(router: router, chatRoomUseCase: chatRoomUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase)
        
        sut.startOrJoinMeetingTapped()
        
        XCTAssertTrue(router.presentWaitingRoom_calledTimes == 1)
    }
    
    @MainActor
    func testUnreadCountString_forChatListItemUnreadCountLessThanZero_shouldBePositiveWithPlus() {
        let sut = ChatRoomViewModelFactory.make(chatListItem: ChatListItemEntity(unreadCount: -1))
        
        XCTAssertEqual(sut.unreadCountString, "1+")
    }
    
    @MainActor
    func testUnreadCountString_forChatListItemUnreadCountGreaterThanZeroAndLessThan100_shouldBePositiveWithoutPlus() {
        let sut = ChatRoomViewModelFactory.make(chatListItem: ChatListItemEntity(unreadCount: 50))
        
        XCTAssertEqual(sut.unreadCountString, "50")
    }
    
    @MainActor
    func testUnreadCountString_forChatListItemUnreadCountGreaterThan99_shouldBe99WithPlu() {
        let sut = ChatRoomViewModelFactory.make(chatListItem: ChatListItemEntity(unreadCount: 123))
        
        XCTAssertEqual(sut.unreadCountString, "99+")
    }
}

class ChatRoomViewModelFactory {
    @MainActor
    static func make(
        chatListItem: ChatListItemEntity = ChatListItemEntity(),
        router: some ChatRoomsListRouting = MockChatRoomsListRouter(),
        chatRoomUseCase: some ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol = MockChatRoomUserUseCase(),
        userImageUseCase: some UserImageUseCaseProtocol = MockUserImageUseCase(),
        chatUseCase: some ChatUseCaseProtocol = MockChatUseCase(),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        megaHandleUseCase: some MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
        callController: some CallControllerProtocol = MockCallController(),
        callUseCase: some CallUseCaseProtocol = MockCallUseCase(),
        audioSessionUseCase: some AudioSessionUseCaseProtocol = MockAudioSessionUseCase(),
        scheduledMeetingUseCase: some ScheduledMeetingUseCaseProtocol = MockScheduledMeetingUseCase(),
        chatNotificationControl: ChatNotificationControl? = nil,
        permissionRouter: MockPermissionAlertRouter? = nil,
        chatListItemCacheUseCase: some ChatListItemCacheUseCaseProtocol = MockChatListItemCacheUseCase(),
        chatListItemDescription: ChatListItemDescriptionEntity? = nil,
        chatListItemAvatar: ChatListItemAvatarEntity? = nil
    ) -> ChatRoomViewModel {
        let _permissionRouter = if let permissionRouter {
            permissionRouter
        } else {
            MockPermissionAlertRouter()
        }
        return .init(
            chatListItem: chatListItem,
            router: router,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            userImageUseCase: userImageUseCase,
            chatUseCase: chatUseCase,
            accountUseCase: accountUseCase,
            megaHandleUseCase: megaHandleUseCase, 
            callController: callController,
            callUseCase: callUseCase,
            audioSessionUseCase: audioSessionUseCase,
            scheduledMeetingUseCase: scheduledMeetingUseCase,
            chatNotificationControl: chatNotificationControl ?? ChatNotificationControl(delegate: MockPushNotificationControl()),
            permissionRouter: _permissionRouter,
            chatListItemCacheUseCase: chatListItemCacheUseCase,
            chatListItemDescription: chatListItemDescription,
            chatListItemAvatar: chatListItemAvatar
        )
    }
}
