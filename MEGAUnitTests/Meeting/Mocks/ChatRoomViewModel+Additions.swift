@testable import MEGA
import MEGADomain
import MEGADomainMock

extension ChatRoomViewModel {
    convenience init(
        chatListItem: ChatListItemEntity = ChatListItemEntity(),
        router: ChatRoomsListRouting = MockChatRoomsListRouter(),
        chatRoomUseCase: any ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol = MockChatRoomUserUseCase(),
        userImageUseCase: UserImageUseCaseProtocol = MockUserImageUseCase(),
        chatUseCase: any ChatUseCaseProtocol = MockChatUseCase(),
        accountUseCase: any AccountUseCaseProtocol = MockAccountUseCase(),
        megaHandleUseCase: any MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
        callUseCase: CallUseCaseProtocol = MockCallUseCase(),
        audioSessionUseCase: any AudioSessionUseCaseProtocol = MockAudioSessionUseCase(),
        scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol = MockScheduledMeetingUseCase(),
        chatNotificationControl: ChatNotificationControl = ChatNotificationControl(delegate: MockPushNotificationControl()),
        notificationCenter: NotificationCenter = .default,
        isTesting: Bool = true
    ) {
        self.init(chatListItem: chatListItem, router: router, chatRoomUseCase: chatRoomUseCase, chatRoomUserUseCase: chatRoomUserUseCase, userImageUseCase: userImageUseCase, chatUseCase: chatUseCase, accountUseCase: accountUseCase, megaHandleUseCase: megaHandleUseCase, callUseCase: callUseCase, audioSessionUseCase: audioSessionUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase, chatNotificationControl: chatNotificationControl)
    }
}

private final class MockPushNotificationControl: PushNotificationControlProtocol {}
