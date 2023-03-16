import XCTest
@testable import MEGA
import MEGADomain
import MEGADomainMock

final class ChatRoomViewModelTests: XCTestCase {
    
    func test_ScheduledMeetingManagementMessage_MeetingCreatedMyself() async throws {
        let chatListItemEntity = ChatListItemEntity(lastMessageType: .scheduledMeeting, lastMessageSender: 1001)
        let viewModel = ChatRoomViewModel(chatListItem: chatListItemEntity,
                                          accountUseCase: MockAccountUseCase(currentUser: UserEntity(handle: 1001)),
                                          scheduledMeetingUseCase: MockScheduledMeetingUseCase())
        try await viewModel.updateDescription()
        XCTAssertTrue(viewModel.description == Strings.Localizable.Chat.Listing.Description.MeetingCreated.message("Me"))
    }
    
    func test_ScheduledMeetingManagementMessage_MeetingCreatedByOthers() async throws {
        let chatListItemEntity = ChatListItemEntity(lastMessageType: .scheduledMeeting, lastMessageSender: 1002)
        let chatRoomUseCase = MockChatRoomUseCase()
        let userUseCase = MockChatRoomUserUseCase(userDisplayNamesForPeersResult: .success([(handle: 1002, name: "Bob")]))
        let viewModel = ChatRoomViewModel(chatListItem: chatListItemEntity,
                                          chatRoomUseCase: chatRoomUseCase,
                                          chatRoomUserUseCase: userUseCase,
                                          scheduledMeetingUseCase: MockScheduledMeetingUseCase())
        try await viewModel.updateDescription()
        XCTAssertTrue(viewModel.description == Strings.Localizable.Chat.Listing.Description.MeetingCreated.message("Bob"))
    }
}


