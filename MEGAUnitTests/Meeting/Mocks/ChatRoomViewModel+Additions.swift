@testable import MEGA
import MEGADomain
import MEGADomainMock

extension ChatRoomViewModel {
    convenience init(
        chatListItem: ChatListItemEntity = ChatListItemEntity(),
        router: ChatRoomsListRouting = MockChatRoomsListRouter(),
        chatRoomUseCase: ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        userImageUseCase: UserImageUseCaseProtocol = MockUserImageUseCase(),
        chatUseCase: ChatUseCaseProtocol = MockChatUseCase(),
        userUseCase: UserUseCaseProtocol = MockUserUseCase(),
        callUseCase: CallUseCaseProtocol = MockCallUseCase(),
        audioSessionUseCase: AudioSessionUseCaseProtocol = MockAudioSessionUseCase(),
        scheduledMeetingUseCase: ScheduledMeetingUseCaseProtocol,
        chatNotificationControl: ChatNotificationControl = ChatNotificationControl(delegate: MockPushNotificationControl()),
        notificationCenter: NotificationCenter = .default,
        isTesting: Bool = true
    ) {
        self.init(
            chatListItem: chatListItem,
            router: router,
            chatRoomUseCase: chatRoomUseCase,
            userImageUseCase: userImageUseCase,
            chatUseCase: chatUseCase,
            userUseCase: userUseCase,
            callUseCase: callUseCase,
            audioSessionUseCase: audioSessionUseCase,
            scheduledMeetingUseCase: scheduledMeetingUseCase,
            chatNotificationControl: chatNotificationControl
        )
    }
}


fileprivate final class MockPushNotificationControl: PushNotificationControlProtocol {}
