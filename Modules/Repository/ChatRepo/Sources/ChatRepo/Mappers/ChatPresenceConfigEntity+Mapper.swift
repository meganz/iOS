import MEGAChatSdk
import MEGADomain

public extension MEGAChatPresenceConfig {
    func toChatPresenceConfigEntity() -> ChatPresenceConfigEntity {
        ChatPresenceConfigEntity(
            status: onlineStatus.toChatStatusEntity(),
            autoAwayEnabled: isAutoAwayEnabled,
            autoAwayTimeout: autoAwayTimeout,
            persist: isPersist,
            pending: isPending,
            lastGreenVisible: isLastGreenVisible
        )
    }
}
