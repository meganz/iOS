import MEGADomain

public final class MockNotificationsRepository: NotificationsRepositoryProtocol {
    private var lastReadNotification: NotificationIDEntity
    private let enabledNotifications: [NotificationIDEntity]
    private let notificationsResult: Result<[NotificationEntity], Error>
    private let unreadNotificationIDs: [NotificationIDEntity]
    
    public static var newRepo: MockNotificationsRepository {
        MockNotificationsRepository()
    }
    
    public init(
        lastReadNotification: NotificationIDEntity = 1,
        enabledNotifications: [NotificationIDEntity] = [1],
        notificationsResult: Result<[NotificationEntity], Error> = .failure(GenericErrorEntity()),
        unreadNotificationIDs: [NotificationIDEntity] = [1]
    ) {
        self.lastReadNotification = lastReadNotification
        self.enabledNotifications = enabledNotifications
        self.notificationsResult = notificationsResult
        self.unreadNotificationIDs = unreadNotificationIDs
    }
    
    public func fetchLastReadNotification() async throws -> NotificationIDEntity {
        lastReadNotification
    }
    
    public func updateLastReadNotification(notificationId: NotificationIDEntity) async throws {
        lastReadNotification = notificationId
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
