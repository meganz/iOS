@testable import MEGA
import MEGADomain
import MEGADomainMock

extension MeetingParticipantsLayoutViewModel {
    convenience init(
        containerViewModel: MeetingContainerViewModel = MeetingContainerViewModel(),
        callUseCase: some CallUseCaseProtocol = MockCallUseCase(),
        captureDeviceUseCase: some CaptureDeviceUseCaseProtocol = MockCaptureDeviceUseCase(),
        localVideoUseCase: some CallLocalVideoUseCaseProtocol = MockCallLocalVideoUseCase(),
        remoteVideoUseCase: some CallRemoteVideoUseCaseProtocol = MockCallRemoteVideoUseCase(),
        chatRoomUseCase: some ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol = MockChatRoomUserUseCase(),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        userImageUseCase: some UserImageUseCaseProtocol = MockUserImageUseCase(),
        analyticsEventUseCase: some AnalyticsEventUseCaseProtocol = MockAnalyticsEventUseCase(),
        chatRoom: ChatRoomEntity = ChatRoomEntity(),
        megaHandleUseCase: some MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
        call: CallEntity = CallEntity(),
        preferenceUseCase: some PreferenceUseCaseProtocol = PreferenceUseCase.default,
        isTesting: Bool = true
    ) {
        self.init(
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
