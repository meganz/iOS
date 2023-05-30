@testable import MEGA
import MEGADomainMock
import MEGADomain

extension ChatRoomsListViewModel {
    
    convenience init(
        router: ChatRoomsListRouting = MockChatRoomsListRouter(),
        chatUseCase: ChatUseCaseProtocol = MockChatUseCase(),
        contactsUseCase: ContactsUseCaseProtocol = MockContactsUseCase(),
        networkMonitorUseCase: NetworkMonitorUseCaseProtocol = MockNetworkMonitorUseCase(),
        accountUseCase: AccountUseCaseProtocol = MockAccountUseCase(),
        chatRoomUseCase: ChatRoomUseCaseProtocol = MockChatRoomUseCase(),
        scheduledMeetingUseCase: ScheduledMeetingUseCaseProtocol = MockScheduledMeetingUseCase(),
        notificationCenter: NotificationCenter = NotificationCenter.default,
        chatType: ChatViewType = .regular,
        chatViewMode: ChatViewMode = .chats,
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
            chatViewMode: chatViewMode
        )
    }
}
