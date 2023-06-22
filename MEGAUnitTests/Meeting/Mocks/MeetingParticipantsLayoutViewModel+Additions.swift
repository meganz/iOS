@testable import MEGA
import MEGADomain
import MEGADomainMock

extension MeetingParticipantsLayoutViewModel {
    convenience init(
        router: some MeetingParticipantsLayoutRouting = MockCallViewRouter(),
        containerViewModel: MeetingContainerViewModel = MeetingContainerViewModel(),
        callUseCase: CallUseCaseProtocol = MockCallUseCase(),
        captureDeviceUseCase: any CaptureDeviceUseCaseProtocol = MockCaptureDeviceUseCase(),
        localVideoUseCase: CallLocalVideoUseCaseProtocol = MockCallLocalVideoUseCase(),
        remoteVideoUseCase: CallRemoteVideoUseCaseProtocol = MockCallRemoteVideoUseCase(),
        chatRoomUseCase: any ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol = MockChatRoomUserUseCase(),
        accountUseCase: any AccountUseCaseProtocol = MockAccountUseCase(),
        userImageUseCase: UserImageUseCaseProtocol = MockUserImageUseCase(),
        analyticsEventUseCase: any AnalyticsEventUseCaseProtocol = MockAnalyticsEventUseCase(),
        chatRoom: ChatRoomEntity = ChatRoomEntity(),
        megaHandleUseCase: any MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
        call: CallEntity = CallEntity(),
        preferenceUseCase: any PreferenceUseCaseProtocol = PreferenceUseCase.default,
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
            chatRoomUserUseCase: chatRoomUserUseCase,
            accountUseCase: accountUseCase,
            userImageUseCase: userImageUseCase,
            analyticsEventUseCase: analyticsEventUseCase,
            megaHandleUseCase: megaHandleUseCase,
            chatRoom: chatRoom,
            call: call
        )
    }
}
