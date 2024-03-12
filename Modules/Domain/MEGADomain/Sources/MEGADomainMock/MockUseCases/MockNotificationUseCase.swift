import MEGADomain

public class MockNotificationUseCase: NotificationsUseCaseProtocol {
    private var lastReadNotification: NotificationIDEntity
    private let enabledNotifications: [NotificationIDEntity]
    private let notifications: [NotificationEntity]
    
    public init(
        lastReadNotification: NotificationIDEntity = 1,
        enabledNotifications: [NotificationIDEntity] = [],
        notifications: [NotificationEntity] = []
    ) {
        self.lastReadNotification = lastReadNotification
        self.enabledNotifications = enabledNotifications
        self.notifications = notifications
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
        notifications
    }
}
