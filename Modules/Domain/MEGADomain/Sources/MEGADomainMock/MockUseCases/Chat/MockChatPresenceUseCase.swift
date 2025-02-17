import MEGADomain
import MEGASwift

public final class MockChatPresenceUseCase: ChatPresenceUseCaseProtocol, @unchecked Sendable {
    
    private let chatPresenceConfig: ChatPresenceConfigEntity?
    private let presenceConfigUpdates: AnyAsyncSequence<ChatPresenceConfigEntity>
    private let presenceLastGreenUpdates: AnyAsyncSequence<(userHandle: ChatIdEntity, lastGreen: Int)>
    private let onlineStatusUpdates: AnyAsyncSequence<(userHandle: HandleEntity, status: ChatStatusEntity, inProgress: Bool)>
    
    public var requestLastGreen_calledTimes = 0
    public var setLastGreenVisible_calledTimes = 0
    public var setAutoAwayPresence_calledTimes = 0
    public var setPresencePersist_calledTimes = 0
    public var setOnlineStatus_calledTimes = 0
    
    public init(
        chatPresenceConfig: ChatPresenceConfigEntity? = nil,
        presenceConfigUpdates: AnyAsyncSequence<ChatPresenceConfigEntity> = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        monitorPresenceLastSeenUpdates: AnyAsyncSequence<(userHandle: ChatIdEntity, lastGreen: Int) > = EmptyAsyncSequence().eraseToAnyAsyncSequence(),
        onlineStatusUpdates: AnyAsyncSequence<(userHandle: HandleEntity, status: ChatStatusEntity, inProgress: Bool)> = EmptyAsyncSequence().eraseToAnyAsyncSequence()
    ) {
        self.chatPresenceConfig = chatPresenceConfig
        self.presenceConfigUpdates = presenceConfigUpdates
        self.presenceLastGreenUpdates = monitorPresenceLastSeenUpdates
        self.onlineStatusUpdates = onlineStatusUpdates
    }
    
    public func setAutoAwayPresence(_ enabled: Bool, seconds: Int) {
        setAutoAwayPresence_calledTimes += 1
    }
    
    public func monitorOnPresenceConfigUpdates() -> AnyAsyncSequence<ChatPresenceConfigEntity> {
        presenceConfigUpdates.eraseToAnyAsyncSequence()
    }
    
    public func presenceConfig() -> ChatPresenceConfigEntity? {
        chatPresenceConfig
    }
    
    public func requestLastGreen(for user: HandleEntity) {
        requestLastGreen_calledTimes += 1
    }
    
    public func setLastGreenVisible(_ visible: Bool) {
        setLastGreenVisible_calledTimes += 1
    }
    
    public func monitorOnPresenceLastGreenUpdates() -> AnyAsyncSequence<(userHandle: HandleEntity, lastGreen: Int)> {
        presenceLastGreenUpdates.eraseToAnyAsyncSequence()
    }
    
    public func setPresencePersist(_ enabled: Bool) {
        setPresencePersist_calledTimes += 1
    }
    
    public func setOnlineStatus(_ status: ChatStatusEntity) {
        setOnlineStatus_calledTimes += 1
    }

    public func onlineStatus() -> ChatStatusEntity {
        chatPresenceConfig?.status ?? .invalid
    }
    
    public func monitorOnChatOnlineStatusUpdate() -> AnyAsyncSequence<(userHandle: HandleEntity, status: ChatStatusEntity, inProgress: Bool)> {
        onlineStatusUpdates.eraseToAnyAsyncSequence()
    }
}
