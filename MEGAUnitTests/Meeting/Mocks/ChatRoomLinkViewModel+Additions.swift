@testable import MEGA
import MEGADomain
import MEGAPresentation
import MEGAPresentationMock

extension ChatRoomLinkViewModel {
    convenience init(
        router: some MeetingInfoRouting = MockMeetingInfoRouter(),
        chatRoom: ChatRoomEntity = ChatRoomEntity(),
        scheduledMeeting: ScheduledMeetingEntity = ScheduledMeetingEntity(),
        chatLinkUseCase: some ChatLinkUseCaseProtocol = MockChatLinkUseCase(),
        tracker: some AnalyticsTracking = MockTracker(),
        subtitle: String = "",
        isTesting: Bool = true
    ) {
        self.init(
            router: router,
            chatRoom: chatRoom,
            scheduledMeeting: scheduledMeeting,
            chatLinkUseCase: chatLinkUseCase,
            tracker: tracker,
            subtitle: subtitle
        )
    }
}
