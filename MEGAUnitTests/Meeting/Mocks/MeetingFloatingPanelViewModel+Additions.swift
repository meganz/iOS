@testable import MEGA
import MEGADomain
import MEGADomainMock

extension MeetingFloatingPanelViewModel {
    convenience init(
        router: MeetingFloatingPanelRouting = MockMeetingFloatingPanelRouter(),
        containerViewModel: MeetingContainerViewModel = MeetingContainerViewModel(),
        chatRoom: ChatRoomEntity = ChatRoomEntity(),
        isSpeakerEnabled: Bool = false,
        callCoordinatorUseCase: CallCoordinatorUseCaseProtocol = MockCallCoordinatorUseCase(),
        callUseCase: CallUseCaseProtocol = MockCallUseCase(),
        audioSessionUseCase: any AudioSessionUseCaseProtocol = MockAudioSessionUseCase(),
        devicePermissionUseCase: DevicePermissionCheckingProtocol = DevicePermissionCheckingProtocol.mock(),
        captureDeviceUseCase: any CaptureDeviceUseCaseProtocol = MockCaptureDeviceUseCase(),
        localVideoUseCase: CallLocalVideoUseCaseProtocol = MockCallLocalVideoUseCase(),
        accountUseCase: any AccountUseCaseProtocol = MockAccountUseCase(),
        chatRoomUseCase: any ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        megaHandleUseCase: any MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
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
            accountUseCase: accountUseCase,
            chatRoomUseCase: chatRoomUseCase,
            megaHandleUseCase: megaHandleUseCase
        )
    }
}
