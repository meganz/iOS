@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPermissionsMock

extension WaitingRoomViewModel {
    convenience init(
        scheduledMeeting: ScheduledMeetingEntity = ScheduledMeetingEntity(),
        router: some WaitingRoomViewRouting = MockWaitingRoomViewRouter(),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        userImageUseCase: some UserImageUseCaseProtocol = MockUserImageUseCase(),
        localVideoUseCase: some CallLocalVideoUseCaseProtocol = MockCallLocalVideoUseCase(),
        audioSessionUseCase: some AudioSessionUseCaseProtocol = MockAudioSessionUseCase(),
        permissionHandler: some DevicePermissionsHandling = MockDevicePermissionHandler(),
        isTesting: Bool = true
    ) {
        self.init(
            scheduledMeeting: scheduledMeeting,
            router: router,
            accountUseCase: accountUseCase,
            userImageUseCase: userImageUseCase,
            localVideoUseCase: localVideoUseCase,
            audioSessionUseCase: audioSessionUseCase,
            permissionHandler: permissionHandler
        )
    }
}
