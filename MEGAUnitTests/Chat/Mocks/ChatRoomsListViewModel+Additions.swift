@testable import MEGA
import MEGADomain
import MEGADomainMock
import MEGAPermissions
import MEGAPermissionsMock
import MEGAPresentation

extension ChatRoomsListViewModel {
    
    convenience init(
        router: ChatRoomsListRouting = MockChatRoomsListRouter(),
        chatUseCase: any ChatUseCaseProtocol = MockChatUseCase(),
        contactsUseCase: any ContactsUseCaseProtocol = MockContactsUseCase(),
        networkMonitorUseCase: any NetworkMonitorUseCaseProtocol = MockNetworkMonitorUseCase(),
        accountUseCase: any AccountUseCaseProtocol = MockAccountUseCase(),
        chatRoomUseCase: any ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        scheduledMeetingUseCase: any ScheduledMeetingUseCaseProtocol = MockScheduledMeetingUseCase(),
        userAttributeUseCase: any UserAttributeUseCaseProtocol = MockUserAttributeUseCase(),
        notificationCenter: NotificationCenter = NotificationCenter.default,
        chatType: ChatViewType = .regular,
        chatViewMode: ChatViewMode = .chats,
        permissionHandler: some DevicePermissionsHandling = MockDevicePermissionHandler(),
        permissionAlertRouter: some PermissionAlertRouting = MockPermissionAlertRouter(),
        featureFlagProvider: some FeatureFlagProviderProtocol = MockFeatureFlagProvider(list: [.scheduleMeeting: true]),
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
            userAttributeUseCase: userAttributeUseCase,
            notificationCenter: notificationCenter,
            chatType: chatType,
            chatViewMode: chatViewMode,
            permissionHandler: permissionHandler,
            permissionAlertRouter: permissionAlertRouter,
            featureFlagProvider: featureFlagProvider
        )
    }
}
