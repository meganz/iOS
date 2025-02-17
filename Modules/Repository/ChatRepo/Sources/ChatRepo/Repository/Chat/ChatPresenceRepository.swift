import MEGAChatSdk
import MEGADomain
import MEGASwift

public final class ChatPresenceRepository: ChatPresenceRepositoryProtocol {
    public static var newRepo: ChatPresenceRepository {
        ChatPresenceRepository(
            chatSDK: .sharedChatSdk,
            chatUpdatesProvider: ChatUpdatesProvider(sdk: .sharedChatSdk)
        )
    }
    private let chatSDK: MEGAChatSdk
    private let chatUpdatesProvider: any ChatUpdatesProviderProtocol

    public init(
        chatSDK: MEGAChatSdk,
        chatUpdatesProvider: some ChatUpdatesProviderProtocol
    ) {
        self.chatSDK = chatSDK
        self.chatUpdatesProvider = chatUpdatesProvider
    }
    
    public func setAutoAwayPresence(_ enabled: Bool, seconds: Int) {
        chatSDK.setPresenceAutoaway(enabled, timeout: seconds)
    }
    
    public var monitorOnPresenceConfigUpdates: AnyAsyncSequence<ChatPresenceConfigEntity> {
        chatUpdatesProvider.presenceConfigUpdates
    }
    
    public func presenceConfig() -> ChatPresenceConfigEntity? {
        chatSDK.presenceConfig()?.toChatPresenceConfigEntity()
    }
    
    public func requestLastGreen(for user: HandleEntity) {
        chatSDK.requestLastGreen(user)
    }
    
    public func setLastGreenVisible(_ visible: Bool) {
        chatSDK.setLastGreenVisible(visible)
    }
    
    public var monitorLastGreenUpdates: AnyAsyncSequence<(userHandle: HandleEntity, lastGreen: Int)> {
        chatUpdatesProvider.presenceLastGreenUpdates
    }
    
    public func setPresencePersist(_ enabled: Bool) {
        chatSDK.setPresencePersist(enabled)
    }
    
    public func setOnlineStatus(_ status: ChatStatusEntity) {
        chatSDK.setOnlineStatus(status.toMEGAChatStatus())
    }

    public func onlineStatus() -> ChatStatusEntity {
        chatSDK.onlineStatus().toChatStatusEntity()
    }
    
    public var chatOnlineStatusUpdate: AnyAsyncSequence<(userHandle: HandleEntity, status: ChatStatusEntity, inProgress: Bool)> {
        chatUpdatesProvider.chatOnlineUpdates
    }
}
