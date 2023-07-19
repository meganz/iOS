@testable import MEGA
import MEGADomain
import MEGADomainMock

extension FutureMeetingRoomViewModel {
    convenience init(
        scheduledMeeting: ScheduledMeetingEntity = ScheduledMeetingEntity(),
        nextOccurrence: ScheduledMeetingOccurrenceEntity? = nil,
        router: some ChatRoomsListRouting = MockChatRoomsListRouter(),
        chatRoomUseCase: some ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol = MockChatRoomUserUseCase(),
        userImageUseCase: some UserImageUseCaseProtocol = MockUserImageUseCase(),
        chatUseCase: some ChatUseCaseProtocol = MockChatUseCase(),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        callUseCase: some CallUseCaseProtocol = MockCallUseCase(),
        audioSessionUseCase: some AudioSessionUseCaseProtocol = MockAudioSessionUseCase(),
        scheduledMeetingUseCase: some ScheduledMeetingUseCaseProtocol = MockScheduledMeetingUseCase(),
        megaHandleUseCase: some MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
        permissionAlertRouter: some PermissionAlertRouting = MockPermissionAlertRouter(),
        chatNotificationControl: ChatNotificationControl = ChatNotificationControl(delegate: MockPushNotificationControl()),
        isTesting: Bool = true
    ) {
        self.init(
            scheduledMeeting: scheduledMeeting,
            nextOccurrence: nextOccurrence,
            router: router,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            userImageUseCase: userImageUseCase,
            chatUseCase: chatUseCase,
            accountUseCase: accountUseCase,
            callUseCase: callUseCase,
            audioSessionUseCase: audioSessionUseCase,
            scheduledMeetingUseCase: scheduledMeetingUseCase,
            megaHandleUseCase: megaHandleUseCase,
            permissionAlertRouter: permissionAlertRouter,
            chatNotificationControl: chatNotificationControl
        )
    }
}

private final class MockPushNotificationControl: PushNotificationControlProtocol {}
