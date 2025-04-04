import MEGADomain

public struct MockNotificationsRepository: NotificationsRepositoryProtocol {
    public actor State {
        public var lastReadNotification: NotificationIDEntity
        
        public init(lastReadNotification: NotificationIDEntity) {
            self.lastReadNotification = lastReadNotification
        }
        
        func updateLastReadNotification(notificationId: NotificationIDEntity) {
            self.lastReadNotification = notificationId
        }
    }
    private let state: State
    private let enabledNotifications: [NotificationIDEntity]
    private let notificationsResult: Result<[NotificationEntity], any Error>
    private let unreadNotificationIDs: [NotificationIDEntity]
    
    public static var newRepo: MockNotificationsRepository {
        MockNotificationsRepository()
    }
    
    public init(
        lastReadNotification: NotificationIDEntity = 1,
        enabledNotifications: [NotificationIDEntity] = [1],
        notificationsResult: Result<[NotificationEntity], any Error> = .failure(GenericErrorEntity()),
        unreadNotificationIDs: [NotificationIDEntity] = [1]
    ) {
        state = State(lastReadNotification: lastReadNotification)
        self.enabledNotifications = enabledNotifications
        self.notificationsResult = notificationsResult
        self.unreadNotificationIDs = unreadNotificationIDs
    }
    
    public func fetchLastReadNotification() async throws -> NotificationIDEntity {
        await state.lastReadNotification
    }
    
    public func updateLastReadNotification(notificationId: NotificationIDEntity) async throws {
        await state.updateLastReadNotification(notificationId: notificationId)
    }
    
    public func fetchEnabledNotifications() -> [NotificationIDEntity] {
        enabledNotifications
    }
    
    public func fetchNotifications() async throws -> [NotificationEntity] {
        try notificationsResult.get()
    }
    
    public func unreadNotificationIDs() async -> [NotificationIDEntity] {
        unreadNotificationIDs
    }
}
