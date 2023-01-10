@testable import MEGA
import MEGADomain
import MEGADomainMock

extension MeetingContainerViewModel {
    
    convenience init(
        router: MeetingContainerRouting = MockMeetingContainerRouter(),
        chatRoom: ChatRoomEntity = ChatRoomEntity(),
        callUseCase: CallUseCaseProtocol = MockCallUseCase(call: CallEntity()),
        chatRoomUseCase: ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        callCoordinatorUseCase: CallCoordinatorUseCaseProtocol = MockCallCoordinatorUseCase(),
        userUseCase: UserUseCaseProtocol = MockUserUseCase(handle: 100, isLoggedIn: true, isGuest: false),
        authUseCase: AuthUseCaseProtocol = MockAuthUseCase(),
        noUserJoinedUseCase: MeetingNoUserJoinedUseCaseProtocol = MockMeetingNoUserJoinedUseCase(),
        analyticsEventUseCase: AnalyticsEventUseCaseProtocol =  MockAnalyticsEventUseCase(),
        isTesting: Bool = true
    ) {
        self.init(
            router: router,
            chatRoom: chatRoom,
            callUseCase: callUseCase,
            chatRoomUseCase: chatRoomUseCase,
            callCoordinatorUseCase: callCoordinatorUseCase,
            userUseCase: userUseCase,
            authUseCase: authUseCase,
            noUserJoinedUseCase: noUserJoinedUseCase,
            analyticsEventUseCase: analyticsEventUseCase
        )
    }
}
