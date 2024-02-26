import MEGADomain

public final class MockNotificationsRepository: NotificationsRepositoryProtocol {
    private var lastReadNotification: NotificationIDEntity
    private var enabledNotififcations: [NotificationIDEntity]
   
    public static var newRepo: MockNotificationsRepository {
        MockNotificationsRepository()
    }
    
    public init(
        lastReadNotification: NotificationIDEntity = 1,
        enabledNotifications: [NotificationIDEntity] = [1]
    ) {
        self.lastReadNotification = lastReadNotification
        self.enabledNotififcations = enabledNotifications
    }
    
    public func fetchLastReadNotification() async throws -> NotificationIDEntity {
        lastReadNotification
    }
    
    public func updateLastReadNotification(notificationId: NotificationIDEntity) async throws {
        lastReadNotification = notificationId
    }
    
    public func fetchEnabledNotifications() -> [NotificationIDEntity] {
        enabledNotififcations
    }
}
