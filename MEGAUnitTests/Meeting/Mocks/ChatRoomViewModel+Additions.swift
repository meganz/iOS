@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPermissionsMock
import MEGAPresentation
import MEGAPresentationMock

extension ChatRoomViewModel {
    convenience init(
        chatListItem: ChatListItemEntity = ChatListItemEntity(),
        router: some ChatRoomsListRouting = MockChatRoomsListRouter(),
        chatRoomUseCase: some ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol = MockChatRoomUserUseCase(),
        userImageUseCase: some UserImageUseCaseProtocol = MockUserImageUseCase(),
        chatUseCase: some ChatUseCaseProtocol = MockChatUseCase(),
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        megaHandleUseCase: some MEGAHandleUseCaseProtocol = MockMEGAHandleUseCase(),
        callUseCase: some CallUseCaseProtocol = MockCallUseCase(),
        audioSessionUseCase: some AudioSessionUseCaseProtocol = MockAudioSessionUseCase(),
        scheduledMeetingUseCase: some ScheduledMeetingUseCaseProtocol = MockScheduledMeetingUseCase(),
        chatNotificationControl: ChatNotificationControl = ChatNotificationControl(delegate: MockPushNotificationControl()),
        permissionRouter: some PermissionAlertRouting = MockPermissionAlertRouter(),
        chatListItemCacheUseCase: some ChatListItemCacheUseCaseProtocol = MockChatListItemCacheUseCase(),
        chatListItemDescription: ChatListItemDescriptionEntity? = nil,
        chatListItemAvatar: ChatListItemAvatarEntity? = nil,
        isTesting: Bool = true
    ) {
        self.init(
            chatListItem: chatListItem,
            router: router,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            userImageUseCase: userImageUseCase,
            chatUseCase: chatUseCase,
            accountUseCase: accountUseCase,
            megaHandleUseCase: megaHandleUseCase,
            callUseCase: callUseCase,
            audioSessionUseCase: audioSessionUseCase,
            scheduledMeetingUseCase: scheduledMeetingUseCase,
            chatNotificationControl: chatNotificationControl,
            permissionRouter: permissionRouter,
            chatListItemCacheUseCase: chatListItemCacheUseCase,
            chatListItemDescription: chatListItemDescription,
            chatListItemAvatar: chatListItemAvatar
        )
    }
}

private final class MockPushNotificationControl: PushNotificationControlProtocol {}
