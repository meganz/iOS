import MEGASwift

public protocol ChatPresenceRepositoryProtocol: RepositoryProtocol, Sendable {
    func setAutoAwayPresence(_ enabled: Bool, seconds: Int64)
    var monitorOnPresenceConfigUpdates: AnyAsyncSequence<ChatPresenceConfigEntity> { get }
    func presenceConfig() -> ChatPresenceConfigEntity?
    func requestLastGreen(for user: HandleEntity)
    func setLastGreenVisible(_ visible: Bool)
    var monitorLastGreenUpdates: AnyAsyncSequence<(userHandle: HandleEntity, lastGreen: Int)> { get }
    func setPresencePersist(_ enabled: Bool)
    func setOnlineStatus(_ status: ChatStatusEntity)
    func onlineStatus() -> ChatStatusEntity
    var chatOnlineStatusUpdate: AnyAsyncSequence<(userHandle: HandleEntity, status: ChatStatusEntity, inProgress: Bool)> { get }
}
