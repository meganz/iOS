@testable import MEGA
import MEGADomain
import MEGADomainMock

extension MeetingParticipantsLayoutViewModel {
    convenience init(
        router: MeetingParticipantsLayoutRouting = MockCallViewRouter(),
        containerViewModel: MeetingContainerViewModel = MeetingContainerViewModel(),
        callUseCase: CallUseCaseProtocol = MockCallUseCase(),
        captureDeviceUseCase: CaptureDeviceUseCaseProtocol = MockCaptureDeviceUseCase(),
        localVideoUseCase: CallLocalVideoUseCaseProtocol = MockCallLocalVideoUseCase(),
        remoteVideoUseCase: CallRemoteVideoUseCaseProtocol = MockCallRemoteVideoUseCase(),
        chatRoomUseCase: ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        accountUseCase: AccountUseCaseProtocol = MockAccountUseCase(),
        userImageUseCase: UserImageUseCaseProtocol = MockUserImageUseCase(),
        analyticsEventUseCase: AnalyticsEventUseCaseProtocol = MockAnalyticsEventUseCase(),
        chatRoom: ChatRoomEntity = ChatRoomEntity(),
        call: CallEntity = CallEntity(),
        preferenceUseCase: PreferenceUseCaseProtocol = PreferenceUseCase.default,
        isTesting: Bool = true
    ) {
        self.init(
            router: router,
            containerViewModel: containerViewModel,
            callUseCase: callUseCase,
            captureDeviceUseCase: captureDeviceUseCase,
            localVideoUseCase: localVideoUseCase,
            remoteVideoUseCase: remoteVideoUseCase,
            chatRoomUseCase: chatRoomUseCase,
            accountUseCase: accountUseCase,
            userImageUseCase: userImageUseCase,
            analyticsEventUseCase: analyticsEventUseCase,
            chatRoom: chatRoom,
            call: call
        )
    }
}
