@testable import MEGA
import MEGAAnalyticsiOS
import MEGADomain
import MEGADomainMock
import MEGAPresentation
import MEGAPresentationMock

extension MeetingContainerViewModel {
    
    convenience init(
        router: some MeetingContainerRouting = MockMeetingContainerRouter(),
        chatRoom: ChatRoomEntity = ChatRoomEntity(),
        callUseCase: some CallUseCaseProtocol = MockCallUseCase(call: CallEntity()),
        callUpdateUseCase: some CallUpdateUseCaseProtocol = MockCallUpdateUseCase(),
        chatRoomUseCase: some ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        chatUseCase: some ChatUseCaseProtocol = MockChatUseCase(),
        scheduledMeetingUseCase: some ScheduledMeetingUseCaseProtocol = MockScheduledMeetingUseCase(),
        accountUseCase: any AccountUseCaseProtocol = MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
        authUseCase: some AuthUseCaseProtocol = MockAuthUseCase(),
        noUserJoinedUseCase: some MeetingNoUserJoinedUseCaseProtocol = MockMeetingNoUserJoinedUseCase(),
        analyticsEventUseCase: some AnalyticsEventUseCaseProtocol =  MockAnalyticsEventUseCase(),
        megaHandleUseCase: some MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
        callController: some CallControllerProtocol = MockCallController(),
        tracker: some AnalyticsTracking = MockTracker(),
        isTesting: Bool = true
    ) {
        self.init(
            router: router,
            chatRoom: chatRoom,
            callUseCase: callUseCase,
            callUpdateUseCase: callUpdateUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatUseCase: chatUseCase,
            scheduledMeetingUseCase: scheduledMeetingUseCase,
            accountUseCase: accountUseCase,
            authUseCase: authUseCase,
            noUserJoinedUseCase: noUserJoinedUseCase,
            analyticsEventUseCase: analyticsEventUseCase,
            megaHandleUseCase: megaHandleUseCase,
            callController: callController,
            tracker: tracker
        )
    }
}
