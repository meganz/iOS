public protocol NotificationSettingsUseCaseProtocol: Sendable {
    func getPushNotificationSettings() async throws -> NotificationSettingsEntity
    func setPushNotificationSettings(_ settings: NotificationSettingsEntity) async throws -> NotificationSettingsEntity
}

public struct NotificationSettingsUseCase<T: NotificationSettingsRepositoryProtocol>: NotificationSettingsUseCaseProtocol {
    private let repository: T
    
    public init(repository: T) {
        self.repository = repository
    }
    
    public func getPushNotificationSettings() async throws -> NotificationSettingsEntity {
        try await repository.getPushNotificationSettings()
    }
    
    public func setPushNotificationSettings(_ settings: NotificationSettingsEntity) async throws -> NotificationSettingsEntity {
        try await repository.setPushNotificationSettings(settings)
    }
}
