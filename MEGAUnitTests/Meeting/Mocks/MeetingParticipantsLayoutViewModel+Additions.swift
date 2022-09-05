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
        userUseCase: UserUseCaseProtocol = MockUserUseCase(),
        userImageUseCase: UserImageUseCaseProtocol = MockUserImageUseCase(),
        statsUseCase: MeetingStatsUseCaseProtocol = MockMeetingStatsUseCase(),
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
            userUseCase: userUseCase,
            userImageUseCase: userImageUseCase,
            statsUseCase: statsUseCase,
            chatRoom: chatRoom,
            call: call
        )
    }
}
