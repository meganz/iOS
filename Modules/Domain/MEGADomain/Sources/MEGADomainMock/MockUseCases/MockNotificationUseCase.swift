import MEGADomain

public final class MockNotificationUseCase: NotificationsUseCaseProtocol, @unchecked Sendable {
    private var lastReadNotification: NotificationIDEntity
    private let notifications: [NotificationEntity]
    private let unreadNotificationIDs: [NotificationIDEntity]
    public var enabledNotifications: [NotificationIDEntity]
    
    public init(
        lastReadNotification: NotificationIDEntity = 1,
        enabledNotifications: [NotificationIDEntity] = [],
        notifications: [NotificationEntity] = [],
        unreadNotificationIDs: [NotificationIDEntity] = []
    ) {
        self.lastReadNotification = lastReadNotification
        self.enabledNotifications = enabledNotifications
        self.notifications = notifications
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
        notifications
    }
    
    public func unreadNotificationIDs() async -> [NotificationIDEntity] {
        unreadNotificationIDs
    }
}
