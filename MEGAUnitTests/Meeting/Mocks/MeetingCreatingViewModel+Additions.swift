@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPermissionsMock
import MEGAPresentation

extension MeetingCreatingViewModel {
    convenience init(
        router: some MeetingCreatingViewRouting = MockMeetingCreateRouter(),
        type: MeetingConfigurationType = .guestJoin,
        meetingUseCase: some MeetingCreatingUseCaseProtocol = MockMeetingCreatingUseCase(),
        audioSessionUseCase: some AudioSessionUseCaseProtocol = MockAudioSessionUseCase(),
        localVideoUseCase: some CallLocalVideoUseCaseProtocol = MockCallLocalVideoUseCase(),
        captureDeviceUseCase: some CaptureDeviceUseCaseProtocol = MockCaptureDeviceUseCase(),
        permissionHandler: some DevicePermissionsHandling =  MockDevicePermissionHandler(
            photoAuthorization: .authorized,
            audioAuthorized: false,
            videoAuthorized: false
        ),
        userImageUseCase: some UserImageUseCaseProtocol = MockUserImageUseCase(),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        megaHandleUseCase: some MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
        tracker: some AnalyticsTracking = DIContainer.tracker,
        link: String? = nil,
        userHandle: UInt64 = 0,
        isTesting: Bool = true
    ) {
        self.init(
            router: router,
            type: type,
            meetingUseCase: meetingUseCase,
            audioSessionUseCase: audioSessionUseCase,
            localVideoUseCase: localVideoUseCase,
            captureDeviceUseCase: captureDeviceUseCase,
            permissionHandler: permissionHandler,
            userImageUseCase: userImageUseCase,
            accountUseCase: accountUseCase,
            megaHandleUseCase: megaHandleUseCase,
            tracker: tracker,
            link: link,
            userHandle: userHandle
        )
    }
}
