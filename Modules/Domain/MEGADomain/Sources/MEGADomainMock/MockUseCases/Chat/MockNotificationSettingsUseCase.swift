import MEGADomain

public final class MockNotificationSettingsUseCase: NotificationSettingsUseCaseProtocol, @unchecked Sendable {
    public var notificationSettings: NotificationSettingsEntity
    public var setPushNotificationSettings_calledCount: Int = 0
    
    public init(
        notificationSettings: NotificationSettingsEntity = NotificationSettingsEntity(
            globalChatsDndEnabled: false,
            globalChatsDndTimestamp: 0
        )
    ) {
        self.notificationSettings = notificationSettings
    }
    
    public func getPushNotificationSettings() async throws -> NotificationSettingsEntity {
        notificationSettings
    }
    
    public func setPushNotificationSettings(_ settings: NotificationSettingsEntity) async throws -> NotificationSettingsEntity {
        setPushNotificationSettings_calledCount += 1
        return notificationSettings
    }
}
