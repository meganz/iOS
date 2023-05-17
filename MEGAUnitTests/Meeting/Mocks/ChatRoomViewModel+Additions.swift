@testable import MEGA
import MEGADomain
import MEGADomainMock

extension ChatRoomViewModel {
    convenience init(
        chatListItem: ChatListItemEntity = ChatListItemEntity(),
        router: ChatRoomsListRouting = MockChatRoomsListRouter(),
        chatRoomUseCase: ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        chatRoomUserUseCase: ChatRoomUserUseCaseProtocol = MockChatRoomUserUseCase(),
        userImageUseCase: UserImageUseCaseProtocol = MockUserImageUseCase(),
        chatUseCase: ChatUseCaseProtocol = MockChatUseCase(),
        accountUseCase: AccountUseCaseProtocol = MockAccountUseCase(),
        megaHandleUseCase: MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
        callUseCase: CallUseCaseProtocol = MockCallUseCase(),
        audioSessionUseCase: AudioSessionUseCaseProtocol = MockAudioSessionUseCase(),
        scheduledMeetingUseCase: ScheduledMeetingUseCaseProtocol = MockScheduledMeetingUseCase(),
        chatNotificationControl: ChatNotificationControl = ChatNotificationControl(delegate: MockPushNotificationControl()),
        notificationCenter: NotificationCenter = .default,
        isTesting: Bool = true
    ) {
        self.init(chatListItem: chatListItem, router: router, chatRoomUseCase: chatRoomUseCase, chatRoomUserUseCase: chatRoomUserUseCase, userImageUseCase: userImageUseCase, chatUseCase: chatUseCase, accountUseCase: accountUseCase, megaHandleUseCase: megaHandleUseCase, callUseCase: callUseCase, audioSessionUseCase: audioSessionUseCase, scheduledMeetingUseCase: scheduledMeetingUseCase, chatNotificationControl: chatNotificationControl)
    }
}


fileprivate final class MockPushNotificationControl: PushNotificationControlProtocol {}
