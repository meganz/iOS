@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPermissionsMock

extension MeetingFloatingPanelViewModel {
    convenience init(
        router: some MeetingFloatingPanelRouting = MockMeetingFloatingPanelRouter(),
        containerViewModel: MeetingContainerViewModel = MeetingContainerViewModel(),
        chatRoom: ChatRoomEntity = ChatRoomEntity(),
        isSpeakerEnabled: Bool = false,
        callKitManager: some CallKitManagerProtocol = MockCallKitManager(),
        callUseCase: some CallUseCaseProtocol = MockCallUseCase(),
        audioSessionUseCase: some AudioSessionUseCaseProtocol = MockAudioSessionUseCase(),
        permissionHandler: some DevicePermissionsHandling = MockDevicePermissionHandler(
            photoAuthorization: .denied,
            audioAuthorized: false,
            videoAuthorized: false
        ),
        captureDeviceUseCase: some CaptureDeviceUseCaseProtocol = MockCaptureDeviceUseCase(),
        localVideoUseCase: some CallLocalVideoUseCaseProtocol = MockCallLocalVideoUseCase(),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        chatRoomUseCase: some ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        megaHandleUseCase: some MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
        chatUseCase: some ChatUseCaseProtocol = MockChatUseCase(),
        selectWaitingRoomList: Bool = false,
        isTesting: Bool = true
    ) {
        self.init(
            router: router,
            containerViewModel: containerViewModel,
            chatRoom: chatRoom,
            isSpeakerEnabled: isSpeakerEnabled,
            callKitManager: callKitManager,
            callUseCase: callUseCase,
            audioSessionUseCase: audioSessionUseCase,
            permissionHandler: permissionHandler,
            captureDeviceUseCase: captureDeviceUseCase,
            localVideoUseCase: localVideoUseCase,
            accountUseCase: accountUseCase,
            chatRoomUseCase: chatRoomUseCase,
            megaHandleUseCase: megaHandleUseCase,
            chatUseCase: chatUseCase,
            selectWaitingRoomList: selectWaitingRoomList
        )
    }
}
