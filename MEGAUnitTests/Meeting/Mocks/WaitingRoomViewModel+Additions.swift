@testable import MEGA
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPermissionsMock

extension WaitingRoomViewModel {
    convenience init(
        scheduledMeeting: ScheduledMeetingEntity = ScheduledMeetingEntity(),
        router: some WaitingRoomViewRouting = MockWaitingRoomViewRouter(),
        chatUseCase: some ChatUseCaseProtocol = MockChatUseCase(),
        chatRoomUseCase: some ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        callUseCase: some CallUseCaseProtocol = MockCallUseCase(),
        callUpdateUseCase: some CallUpdateUseCaseProtocol = MockCallUpdateUseCase(),
        callController: some CallControllerProtocol = MockCallController(),
        meetingUseCase: some MeetingCreatingUseCaseProtocol = MockMeetingCreatingUseCase(),
        authUseCase: some AuthUseCaseProtocol = MockAuthUseCase(),
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
        tracker: some AnalyticsTracking = MockTracker(),
        featureFlagProvider: some FeatureFlagProviderProtocol = DIContainer.featureFlagProvider,
        chatLink: String? = nil,
        requestUserHandle: HandleEntity = 0,
        isTesting: Bool = true
    ) {
        self.init(
            scheduledMeeting: scheduledMeeting,
            router: router,
            chatUseCase: chatUseCase,
            chatRoomUseCase: chatRoomUseCase,
            callUseCase: callUseCase,
            callUpdateUseCase: callUpdateUseCase,
            callController: callController,
            meetingUseCase: meetingUseCase,
            authUseCase: authUseCase,
            accountUseCase: accountUseCase,
            megaHandleUseCase: megaHandleUseCase,
            userImageUseCase: userImageUseCase,
            localVideoUseCase: localVideoUseCase,
            captureDeviceUseCase: captureDeviceUseCase,
            audioSessionUseCase: audioSessionUseCase,
            permissionHandler: permissionHandler,
            tracker: tracker,
            featureFlagProvider: featureFlagProvider,
            chatLink: chatLink,
            requestUserHandle: requestUserHandle
        )
    }
}
