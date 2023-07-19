@testable import MEGA
import MEGADomain
import MEGADomainMock

extension MeetingContainerViewModel {
    
    convenience init(
        router: some MeetingContainerRouting = MockMeetingContainerRouter(),
        chatRoom: ChatRoomEntity = ChatRoomEntity(),
        callUseCase: some CallUseCaseProtocol = MockCallUseCase(call: CallEntity()),
        chatRoomUseCase: some ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        callCoordinatorUseCase: some CallCoordinatorUseCaseProtocol = MockCallCoordinatorUseCase(),
        accountUseCase: any AccountUseCaseProtocol = MockAccountUseCase(currentUser: UserEntity(handle: 100), isGuest: false, isLoggedIn: true),
        authUseCase: some AuthUseCaseProtocol = MockAuthUseCase(),
        noUserJoinedUseCase: some MeetingNoUserJoinedUseCaseProtocol = MockMeetingNoUserJoinedUseCase(),
        analyticsEventUseCase: some AnalyticsEventUseCaseProtocol =  MockAnalyticsEventUseCase(),
        megaHandleUseCase: some MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
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
