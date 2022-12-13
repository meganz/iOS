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
            chatNotificationControl: chatNotificationControl
        )
    }
}


fileprivate final class MockPushNotificationControl: PushNotificationControlProtocol {}
