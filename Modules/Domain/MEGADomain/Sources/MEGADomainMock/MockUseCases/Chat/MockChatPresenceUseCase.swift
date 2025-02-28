import MEGADomain
import MEGASwift

public final class MockChatPresenceUseCase: ChatPresenceUseCaseProtocol, @unchecked Sendable {
    
    private let chatPresenceConfig: ChatPresenceConfigEntity?
    private let presenceConfigUpdates: AnyAsyncSequence<ChatPresenceConfigEntity>
    private let presenceConfigContinuation: AsyncStream<ChatPresenceConfigEntity>.Continuation
    private let presenceLastGreenUpdates: AnyAsyncSequence<(userHandle: ChatIdEntity, lastGreen: Int)>
    private let presenceLastGreenContinuation: AsyncStream<(userHandle: ChatIdEntity, lastGreen: Int)>.Continuation
    private let onlineStatusUpdates: AnyAsyncSequence<(userHandle: HandleEntity, status: ChatStatusEntity, inProgress: Bool)>
    private let onlineStatusContinuation: AsyncStream<(userHandle: HandleEntity, status: ChatStatusEntity, inProgress: Bool)>.Continuation

    public var requestLastGreen_calledTimes = 0
    public var setLastGreenVisible_calledTimes = 0
    public var setAutoAwayPresence_calledTimes = 0
    public var setPresencePersist_calledTimes = 0
    public var setOnlineStatus_calledTimes = 0
    
    public init(
        chatPresenceConfig: ChatPresenceConfigEntity? = nil
    ) {
        self.chatPresenceConfig = chatPresenceConfig
        
        // PresenceConfig AsyncStream
        let (presenceConfigStream, presenceConfigContinuation) = AsyncStream
            .makeStream(of: ChatPresenceConfigEntity.self)
        self.presenceConfigUpdates = AnyAsyncSequence(presenceConfigStream)
        self.presenceConfigContinuation = presenceConfigContinuation

        // PresenceLastGreen AsyncStream
        let (presenceLastGreenStream, presenceLastGreenContinuation) = AsyncStream
            .makeStream(of: (userHandle: HandleEntity, lastGreen: Int).self)
        self.presenceLastGreenUpdates = AnyAsyncSequence(presenceLastGreenStream)
        self.presenceLastGreenContinuation = presenceLastGreenContinuation
        
        // ChatOnlineStatus AsyncStream
        let (onlineStatusStream, onlineStatusContinuation) = AsyncStream
            .makeStream(of: (userHandle: HandleEntity, status: ChatStatusEntity, inProgress: Bool).self)
        self.onlineStatusUpdates = AnyAsyncSequence(onlineStatusStream)
        self.onlineStatusContinuation = onlineStatusContinuation
    }
    
    public func setAutoAwayPresence(_ enabled: Bool, seconds: Int64) {
        setAutoAwayPresence_calledTimes += 1
    }
    
    public func monitorOnPresenceConfigUpdates() -> AnyAsyncSequence<ChatPresenceConfigEntity> {
        presenceConfigUpdates.eraseToAnyAsyncSequence()
    }
    
    public func sendOnPresenceConfigUpdate(_ presenceConfigUpdate: ChatPresenceConfigEntity) {
        presenceConfigContinuation.yield(presenceConfigUpdate)
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
    
    public func sendOnPresenceLastGreenUpdate(_ lastGreenUpdate: (userHandle: HandleEntity, lastGreen: Int)) {
        presenceLastGreenContinuation.yield(lastGreenUpdate)
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
    
    public func sendChatOnlineStatusUpdate(_ onlineStatusUpdate: (userHandle: HandleEntity, status: ChatStatusEntity, inProgress: Bool)) {
        onlineStatusContinuation.yield(onlineStatusUpdate)
    }
}
