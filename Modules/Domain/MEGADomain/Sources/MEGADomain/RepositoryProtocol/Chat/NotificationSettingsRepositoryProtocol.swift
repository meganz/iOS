public protocol NotificationSettingsRepositoryProtocol: RepositoryProtocol, Sendable {
    func getPushNotificationSettings() async throws -> NotificationSettingsEntity
    func setPushNotificationSettings(_ settings: NotificationSettingsEntity) async throws -> NotificationSettingsEntity
}
