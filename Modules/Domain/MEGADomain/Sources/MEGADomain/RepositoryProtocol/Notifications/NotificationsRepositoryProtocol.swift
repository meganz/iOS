public protocol NotificationsRepositoryProtocol: RepositoryProtocol {
    func fetchLastReadNotification() async throws -> NotificationIDEntity
    func updateLastReadNotification(notificationId: NotificationIDEntity) async throws
}
