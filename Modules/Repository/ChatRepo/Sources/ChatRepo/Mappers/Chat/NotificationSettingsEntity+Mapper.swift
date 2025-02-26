import MEGADomain
import MEGASdk

public extension MEGAPushNotificationSettings {
    func toNotificationSettingsEntity() -> NotificationSettingsEntity {
        NotificationSettingsEntity(
            globalChatsDndEnabled: globalChatsDndEnabled,
            globalChatsDndTimestamp: globalChatsDNDTimestamp
        )
    }
}

 public extension NotificationSettingsEntity {
    func toMEGAPushNotificationSettings() -> MEGAPushNotificationSettings {
        let pushNotificationSettings = MEGAPushNotificationSettings()
        pushNotificationSettings.globalChatsDndEnabled = globalChatsDndEnabled
        if globalChatsDndTimestamp > 0 {
            pushNotificationSettings.globalChatsDNDTimestamp = globalChatsDndTimestamp
        }
        return pushNotificationSettings
    }
 }
