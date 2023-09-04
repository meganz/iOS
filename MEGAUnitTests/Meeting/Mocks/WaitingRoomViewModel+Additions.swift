@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPermissionsMock

extension WaitingRoomViewModel {
    convenience init(
        scheduledMeeting: ScheduledMeetingEntity = ScheduledMeetingEntity(),
        router: some WaitingRoomViewRouting = MockWaitingRoomViewRouter(),
        chatUseCase: some ChatUseCaseProtocol = MockChatUseCase(),
        callUseCase: some CallUseCaseProtocol = MockCallUseCase(),
        callCoordinatorUseCase: some CallCoordinatorUseCaseProtocol = MockCallCoordinatorUseCase(),
        waitingRoomUseCase: some WaitingRoomUseCaseProtocol = MockWaitingRoomUseCase(),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        megaHandleUseCase: some MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
        userImageUseCase: some UserImageUseCaseProtocol = MockUserImageUseCase(),
        localVideoUseCase: some CallLocalVideoUseCaseProtocol = MockCallLocalVideoUseCase(),
        captureDeviceUseCase: some CaptureDeviceUseCaseProtocol = MockCaptureDeviceUseCase(),
        audioSessionUseCase: some AudioSessionUseCaseProtocol = MockAudioSessionUseCase(),
        permissionHandler: some DevicePermissionsHandling = MockDevicePermissionHandler
            .init(
                photoAuthorization: .authorized,
                audioAuthorized: true,
                videoAuthorized: true
            ),
        isTesting: Bool = true
    ) {
        self.init(
            scheduledMeeting: scheduledMeeting,
            router: router,
            chatUseCase: chatUseCase,
            callUseCase: callUseCase,
            callCoordinatorUseCase: callCoordinatorUseCase,
            waitingRoomUseCase: waitingRoomUseCase,
            accountUseCase: accountUseCase,
            megaHandleUseCase: megaHandleUseCase,
            userImageUseCase: userImageUseCase,
            localVideoUseCase: localVideoUseCase,
            captureDeviceUseCase: captureDeviceUseCase,
            audioSessionUseCase: audioSessionUseCase,
            permissionHandler: permissionHandler
        )
    }
}
