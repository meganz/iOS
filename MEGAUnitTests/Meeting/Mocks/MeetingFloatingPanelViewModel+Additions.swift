@testable import MEGA

extension MeetingFloatingPanelViewModel {
    convenience init(
        router: MeetingFloatingPanelRouting = MockMeetingFloatingPanelRouter(),
        containerViewModel: MeetingContainerViewModel = MeetingContainerViewModel(),
        chatRoom: ChatRoomEntity = ChatRoomEntity(),
        isSpeakerEnabled: Bool = false,
        callCoordinatorUseCase: CallCoordinatorUseCaseProtocol = MockCallCoordinatorUseCase(),
        callUseCase: CallUseCaseProtocol = MockCallUseCase(),
        audioSessionUseCase: AudioSessionUseCaseProtocol = MockAudioSessionUseCase(),
        devicePermissionUseCase: DevicePermissionCheckingProtocol = DevicePermissionCheckingProtocol.mock(),
        captureDeviceUseCase: CaptureDeviceUseCaseProtocol = MockCaptureDeviceUseCase(),
        localVideoUseCase: CallLocalVideoUseCaseProtocol = MockCallLocalVideoUseCase(),
        userUseCase: UserUseCaseProtocol = MockUserUseCase(),
        chatRoomUseCase: ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        isTesting: Bool = true
    ) {
        self.init(
            router: router,
            containerViewModel: containerViewModel,
            chatRoom: chatRoom,
            isSpeakerEnabled: isSpeakerEnabled,
            callCoordinatorUseCase: callCoordinatorUseCase,
            callUseCase: callUseCase,
            audioSessionUseCase: audioSessionUseCase,
            devicePermissionUseCase: devicePermissionUseCase,
            captureDeviceUseCase: captureDeviceUseCase,
            localVideoUseCase: localVideoUseCase,
            userUseCase: userUseCase,
            chatRoomUseCase: chatRoomUseCase
        )
    }
}
