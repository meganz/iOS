@testable import MEGA
import MEGADomain

extension ChatRoomLinkViewModel {
    convenience init(
        router: some MeetingInfoRouting = MockMeetingInfoRouter(),
        chatRoom: ChatRoomEntity = ChatRoomEntity(),
        scheduledMeeting: ScheduledMeetingEntity = ScheduledMeetingEntity(),
        chatLinkUseCase: any ChatLinkUseCaseProtocol = MockChatLinkUseCase(),
        subtitle: String = "",
        isTesting: Bool = true
    ) {
        self.init(
            router: router,
            chatRoom: chatRoom,
            scheduledMeeting: scheduledMeeting,
            chatLinkUseCase: chatLinkUseCase,
            subtitle: subtitle
        )
    }
}
