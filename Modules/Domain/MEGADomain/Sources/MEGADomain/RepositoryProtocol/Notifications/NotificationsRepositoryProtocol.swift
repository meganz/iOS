public protocol NotificationsRepositoryProtocol: RepositoryProtocol {
    func fetchLastReadNotification() async throws -> NotificationIDEntity
    func updateLastReadNotification(notificationId: NotificationIDEntity) async throws
    func fetchEnabledNotifications() -> [NotificationIDEntity]
    func fetchNotifications() async throws -> [NotificationEntity]
}
