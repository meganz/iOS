import MEGASwift

public protocol ChatPresenceUseCaseProtocol: Sendable {
    /// Sets the auto away presence setting with specified enabled state and duration in seconds.
    ///
    /// This function allows you to configure the auto away feature, which automatically sets your presence status to "away" after a specified number of seconds if you are not actively using the app.
    /// Only valid when your selected status is `Online`
    ///
    /// - Parameters:
    ///   - enabled: A boolean value indicating whether the auto away feature should be enabled.
    ///   - seconds: The number of seconds after which your presence status will automatically change to "away".
    func setAutoAwayPresence(_ enabled: Bool, seconds: Int64)

    /// Monitors updates to the chat presence configuration.
    ///
    /// This function returns an asynchronous sequence that emits `ChatPresenceConfigEntity` objects whenever the configuration is updated.
    ///
    /// - Returns: An `AnyAsyncSequence<ChatPresenceConfigEntity>` that you can use to observe changes in the chat presence configuration.
    func monitorOnPresenceConfigUpdates() -> AnyAsyncSequence<ChatPresenceConfigEntity>

    /// Retrieves the current chat presence configuration.
    ///
    /// This function returns the latest configuration for chat presence settings, or `nil` if not ready yet.
    ///
    /// - Returns: A `ChatPresenceConfigEntity` object representing the current configuration, or `nil` if no configuration is set.
    func presenceConfig() -> ChatPresenceConfigEntity?

    /// Requests the last green status for a specific user.
    ///
    /// This function retrieves the last known "green/online" status of a specified user, which can indicate their active or idle state.
    ///
    /// - Parameter user: The handle of the user for whom you want to retrieve the last green status.
    func requestLastGreen(for user: HandleEntity)

    /// Sets the visibility of the last green status for the current user.
    ///
    /// This function allows you to control whether your last "green/online" status should be visible to other users.
    ///
    /// - Parameter visible: A boolean value indicating whether the last green status should be visible.
    func setLastGreenVisible(_ visible: Bool)

    /// Monitors updates to the presence last green status for users.
    ///
    /// This function returns an asynchronous sequence that emits tuples containing the user handle and their last "green/online" status whenever the status is updated.
    ///
    /// - Returns: An `AnyAsyncSequence<(userHandle: HandleEntity, lastGreen: Int)>` that you can use to observe changes in the presence last green status.
    func monitorOnPresenceLastGreenUpdates() -> AnyAsyncSequence<(userHandle: HandleEntity, lastGreen: Int)>

    /// Sets  presence status should persist your current user online status.
    ///
    /// This function allows you to control the online status shown to other users even if you are disconnected.
    ///
    /// - Parameter enabled: A boolean value indicating whether presence status should persist.
    func setPresencePersist(_ enabled: Bool)

    /// Sets the online status of the current user.
    ///
    /// This function allows you to manually set the online status of the user, overriding any automatic presence settings.
    ///
    /// - Parameter status: The `ChatStatusEntity` representing the desired online status.
    func setOnlineStatus(_ status: ChatStatusEntity)

    /// Retrieves the current online status of the user.
    ///
    /// This function returns the current online status of the user. May return a different online status than the online status when the user has configured the auto away option, after the timeout has expired, the status will be Away instead of Online.
    ///
    /// - Returns: A `ChatStatusEntity` representing the current online status of the user.
    func onlineStatus() -> ChatStatusEntity

    /// Monitors updates to the chat online status for a specific user.
    ///
    /// This function returns an asynchronous sequence that emits tuples containing the user handle, their online status, and a boolean indicating if the update is in progress.
    ///
    /// - Returns: An `AnyAsyncSequence<(userHandle: HandleEntity, status: ChatStatusEntity, inProgress: Bool)>` that you can use to observe changes in the chat online status.
    func monitorOnChatOnlineStatusUpdate() -> AnyAsyncSequence<(userHandle: HandleEntity, status: ChatStatusEntity, inProgress: Bool)>
}

public struct ChatPresenceUseCase<T: ChatPresenceRepositoryProtocol>: ChatPresenceUseCaseProtocol {
    private var repository: T

    public init(repository: T) {
        self.repository = repository
    }
    
    public func setAutoAwayPresence(_ enabled: Bool, seconds: Int64) {
        repository.setAutoAwayPresence(enabled, seconds: seconds)
    }
    
    public func monitorOnPresenceConfigUpdates() -> AnyAsyncSequence<ChatPresenceConfigEntity> {
        repository.monitorOnPresenceConfigUpdates
    }
    
    public func presenceConfig() -> ChatPresenceConfigEntity? {
        repository.presenceConfig()
    }
    
    public func requestLastGreen(for user: HandleEntity) {
        repository.requestLastGreen(for: user)
    }
    
    public func setLastGreenVisible(_ visible: Bool) {
        repository.setLastGreenVisible(visible)
    }
    
    public func monitorOnPresenceLastGreenUpdates() -> AnyAsyncSequence<(userHandle: HandleEntity, lastGreen: Int)> {
        repository.monitorLastGreenUpdates
    }
    
    public func setPresencePersist(_ enabled: Bool) {
        repository.setPresencePersist(enabled)
    }
    
    public func setOnlineStatus(_ status: ChatStatusEntity) {
        repository.setOnlineStatus(status)
    }

    public func onlineStatus() -> ChatStatusEntity {
        repository.onlineStatus()
    }
    
    public func monitorOnChatOnlineStatusUpdate() -> AnyAsyncSequence<(userHandle: HandleEntity, status: ChatStatusEntity, inProgress: Bool)> {
        repository.chatOnlineStatusUpdate
    }
}
