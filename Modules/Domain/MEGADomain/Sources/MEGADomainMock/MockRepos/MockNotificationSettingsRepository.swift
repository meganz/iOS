import Foundation
import MEGADomain
import MEGASwift

public final class MockNotificationSettingsRepository: NotificationSettingsRepositoryProtocol, @unchecked Sendable {
    public static var newRepo: MockNotificationSettingsRepository { MockNotificationSettingsRepository() }
    
    public let notificationSettings: NotificationSettingsEntity
    
    // MARK: - Initializer
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
        return notificationSettings
    }
}
