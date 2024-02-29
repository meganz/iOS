import MEGADomain

public final class MockNotificationsRepository: NotificationsRepositoryProtocol {
    private var lastReadNotification: NotificationIDEntity
    private let enabledNotififcations: [NotificationIDEntity]
    private let notificationsResult: Result<[NotificationEntity], Error>
    
    public static var newRepo: MockNotificationsRepository {
        MockNotificationsRepository()
    }
    
    public init(
        lastReadNotification: NotificationIDEntity = 1,
        enabledNotifications: [NotificationIDEntity] = [1],
        notificationsResult: Result<[NotificationEntity], Error> = .failure(GenericErrorEntity())
    ) {
        self.lastReadNotification = lastReadNotification
        self.enabledNotififcations = enabledNotifications
        self.notificationsResult = notificationsResult
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
    
    public func fetchNotifications() async throws -> [NotificationEntity] {
        try notificationsResult.get()
    }
}
