@testable import MEGA
import MEGADomain
import MEGADomainMock

extension FutureMeetingRoomViewModel {
    convenience init(
        scheduledMeeting: ScheduledMeetingEntity = ScheduledMeetingEntity(),
        router: ChatRoomsListRouting = MockChatRoomsListRouter(),
        chatRoomUseCase: ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        userImageUseCase: UserImageUseCaseProtocol = MockUserImageUseCase(),
        chatUseCase: ChatUseCaseProtocol = MockChatUseCase(),
        userUseCase: UserUseCaseProtocol = MockUserUseCase(),
        callUseCase: CallUseCaseProtocol = MockCallUseCase(),
        audioSessionUseCase: AudioSessionUseCaseProtocol = MockAudioSessionUseCase(),
        chatNotificationControl: ChatNotificationControl = ChatNotificationControl(delegate: MockPushNotificationControl()),
        isTesting: Bool = true
    ) {
        self.init(
            scheduledMeeting: scheduledMeeting,
            router: router,
            chatRoomUseCase: chatRoomUseCase,
            userImageUseCase: userImageUseCase,
            chatUseCase: chatUseCase,
            userUseCase: userUseCase,
            callUseCase: callUseCase,
            audioSessionUseCase: audioSessionUseCase,
            chatNotificationControl: chatNotificationControl
        )
    }
}

fileprivate final class MockPushNotificationControl: PushNotificationControlProtocol {}
