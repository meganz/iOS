/// Repository that provides the domain access to the remote notifications including Promos available to the user for Notification Center.
public protocol NotificationsRepositoryProtocol: RepositoryProtocol {
    
    /// Fetch the last read notification ID
    /// - Returns: Last read notification ID. When the ID returned here was `0` it means that no ID was set as last read.
    func fetchLastReadNotification() async throws -> NotificationIDEntity
    
    /// Save the given notificationId as the last read notification.
    /// Note that any notifications with ID equal to or less than the given one will be marked as seen in Notification Center.
    /// - Parameters:
    ///   - notificationId: The notification ID to be saved as last read notification. Value `0` is an invalid ID. Passing `0` will clear a previously set last read value.
    func updateLastReadNotification(notificationId: NotificationIDEntity) async throws
    
    /// Fetch all enabled notification IDs
    /// - Returns: List of NotificationIDEntity
    func fetchEnabledNotifications() -> [NotificationIDEntity]
    
    /// Fetch list of available notifications for Notification Center
    /// - Returns: List of NotificationEntity
    func fetchNotifications() async throws -> [NotificationEntity]
    
    /// Fetch list of unread notification IDs
    /// - Returns: List of NotificationIDEntity
    func unreadNotificationIDs() async -> [NotificationIDEntity]
}
