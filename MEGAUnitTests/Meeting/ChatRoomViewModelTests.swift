@testable import MEGA
import MEGADomain
import MEGADomainMock
import XCTest

final class ChatRoomViewModelTests: XCTestCase {
    
    func test_scheduledMeetingManagementMessage_meetingCreatedMyself() async throws {
        let chatListItemEntity = ChatListItemEntity(lastMessageType: .scheduledMeeting, lastMessageSender: 1001)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(), message: ChatMessageEntity())
        let userUseCase = MockAccountUseCase(currentUser: UserEntity(handle: 1001))
        let viewModel = ChatRoomViewModel(chatListItem: chatListItemEntity,
                                          chatRoomUseCase: chatRoomUseCase,
                                          accountUseCase: userUseCase,
                                          scheduledMeetingUseCase: MockScheduledMeetingUseCase())
        try await viewModel.updateDescription()
        XCTAssertTrue(viewModel.description == Strings.Localizable.Chat.Listing.Description.MeetingCreated.message("Me"))
    }
    
    func test_scheduledMeetingManagementMessage_meetingCreatedByOthers() async throws {
        let chatListItemEntity = ChatListItemEntity(lastMessageType: .scheduledMeeting, lastMessageSender: 1002)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(), message: ChatMessageEntity())
        let userUseCase = MockChatRoomUserUseCase(userDisplayNamesForPeersResult: .success([(handle: 1002, name: "Bob")]))
        let viewModel = ChatRoomViewModel(chatListItem: chatListItemEntity,
                                          chatRoomUseCase: chatRoomUseCase,
                                          chatRoomUserUseCase: userUseCase,
                                          scheduledMeetingUseCase: MockScheduledMeetingUseCase())
        try await viewModel.updateDescription()
        XCTAssertTrue(viewModel.description == Strings.Localizable.Chat.Listing.Description.MeetingCreated.message("Bob"))
    }
    
    func test_scheduledMeetingManagementMessage_meetingCancelledMyself() async throws {
        let chatListItemEntity = ChatListItemEntity(lastMessageType: .scheduledMeeting, lastMessageSender: 1001)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(), message: ChatMessageEntity(), chatMessageScheduledMeetingChange: .cancelled)
        let userUseCase = MockAccountUseCase(currentUser: UserEntity(handle: 1001))
        let viewModel = ChatRoomViewModel(chatListItem: chatListItemEntity,
                                          chatRoomUseCase: chatRoomUseCase,
                                          accountUseCase: userUseCase,
                                          scheduledMeetingUseCase: MockScheduledMeetingUseCase())
        try await viewModel.updateDescription()
        XCTAssertTrue(viewModel.description == Strings.Localizable.Meetings.Scheduled.ManagementMessages.cancelled("Me"))
    }
    
    func test_scheduledMeetingManagementMessage_meetingCancelledByOthers() async throws {
        let chatListItemEntity = ChatListItemEntity(lastMessageType: .scheduledMeeting, lastMessageSender: 1002)
        let chatRoomUseCase = MockChatRoomUseCase(chatRoomEntity: ChatRoomEntity(), message: ChatMessageEntity(), chatMessageScheduledMeetingChange: .cancelled)
        let userUseCase = MockChatRoomUserUseCase(userDisplayNamesForPeersResult: .success([(handle: 1002, name: "Bob")]))
        let viewModel = ChatRoomViewModel(chatListItem: chatListItemEntity,
                                          chatRoomUseCase: chatRoomUseCase,
                                          chatRoomUserUseCase: userUseCase,
                                          scheduledMeetingUseCase: MockScheduledMeetingUseCase())
        try await viewModel.updateDescription()
        XCTAssertTrue(viewModel.description == Strings.Localizable.Meetings.Scheduled.ManagementMessages.cancelled("Bob"))
    }
}
