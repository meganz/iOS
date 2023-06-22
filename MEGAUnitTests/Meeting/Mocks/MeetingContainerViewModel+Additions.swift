@testable import MEGA
import MEGADomain
import MEGADomainMock

extension MeetingContainerViewModel {
    
    convenience init(
        router: some MeetingContainerRouting = MockMeetingContainerRouter(),
        chatRoom: ChatRoomEntity = ChatRoomEntity(),
        callUseCase: CallUseCaseProtocol = MockCallUseCase(call: CallEntity()),
        chatRoomUseCase: any ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        callCoordinatorUseCase: CallCoordinatorUseCaseProtocol = MockCallCoordinatorUseCase(),
        accountUseCase: any AccountUseCaseProtocol = MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
        authUseCase: any AuthUseCaseProtocol = MockAuthUseCase(),
        noUserJoinedUseCase: MeetingNoUserJoinedUseCaseProtocol = MockMeetingNoUserJoinedUseCase(),
        analyticsEventUseCase: any AnalyticsEventUseCaseProtocol =  MockAnalyticsEventUseCase(),
        megaHandleUseCase: any MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
        isTesting: Bool = true
    ) {
        self.init(
            router: router,
            chatRoom: chatRoom,
            callUseCase: callUseCase,
            chatRoomUseCase: chatRoomUseCase,
            callCoordinatorUseCase: callCoordinatorUseCase,
            accountUseCase: accountUseCase,
            authUseCase: authUseCase,
            noUserJoinedUseCase: noUserJoinedUseCase,
            analyticsEventUseCase: analyticsEventUseCase,
            megaHandleUseCase: megaHandleUseCase
        )
    }
}
