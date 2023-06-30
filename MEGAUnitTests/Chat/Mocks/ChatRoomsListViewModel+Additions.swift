@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPermissionsMock

extension ChatRoomsListViewModel {
    
    convenience init(
        router: ChatRoomsListRouting = MockChatRoomsListRouter(),
        chatUseCase: any ChatUseCaseProtocol = MockChatUseCase(),
        contactsUseCase: any ContactsUseCaseProtocol = MockContactsUseCase(),
        networkMonitorUseCase: any NetworkMonitorUseCaseProtocol = MockNetworkMonitorUseCase(),
        accountUseCase: any AccountUseCaseProtocol = MockAccountUseCase(),
        chatRoomUseCase: any ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol = MockScheduledMeetingUseCase(),
        notificationCenter: NotificationCenter = NotificationCenter.default,
        chatType: ChatViewType = .regular,
        chatViewMode: ChatViewMode = .chats,
        permissionHandler: some DevicePermissionsHandling = MockDevicePermissionHandler(),
        permissionAlertRouter: some PermissionAlertRouting = MockPermissionAlertRouter(),
        isTesting: Bool = true
    ) {
        self.init(
            router: router,
            chatUseCase: chatUseCase,
            chatRoomUseCase: chatRoomUseCase,
            contactsUseCase: contactsUseCase,
            networkMonitorUseCase: networkMonitorUseCase,
            accountUseCase: accountUseCase,
            scheduledMeetingUseCase: scheduledMeetingUseCase,
            notificationCenter: notificationCenter,
            chatType: chatType,
            chatViewMode: chatViewMode,
            permissionHandler: permissionHandler,
            permissionAlertRouter: permissionAlertRouter
        )
    }
}
