import MEGAChatSdk
import MEGADomain
import MEGASwift

public protocol ChatUpdatesProviderProtocol: Sendable {
    /// Call updates from `MEGAChatDelegate` `onChatConnectionStateUpdate` as an `AnyAsyncSequence`
    ///
    /// - Returns: `AnyAsyncSequence` that will call chatSdk.add on creation and chatSdk.remove onTermination of `AsyncStream`.
    /// It will yield `(HandleEntity, ChatConnectionStatus)` item until sequence terminated
    var updates: AnyAsyncSequence<(chatId: ChatIdEntity, connectionStatus: ChatConnectionStatus)> { get }
    
    /// Chat room online status updates from `MEGAChatDelegate` `onChatOnlineStatusUpdate` as an `AnyAsyncSequence`
    ///
    /// - Returns: `AnyAsyncSequence` that will call chatSdk.add on creation and chatSdk.remove onTermination of `AsyncStream`.
    /// It will yield `(HandleEntity, ChatStatusEntity, Bool)` item until sequence terminated
    var chatOnlineUpdates: AnyAsyncSequence<(userHandle: HandleEntity, status: ChatStatusEntity, inProgress: Bool)> { get }
    
    /// Chat room online status updates from `MEGAChatDelegate` `onChatPresenceLastGreen` as an `AnyAsyncSequence`
    ///
    /// - Returns: `AnyAsyncSequence` that will call chatSdk.add on creation and chatSdk.remove onTermination of `AsyncStream`.
    /// It will yield `(HandleEntity, Int)` item until sequence terminated
    var presenceLastGreenUpdates: AnyAsyncSequence<(userHandle: HandleEntity, lastGreen: Int)> { get }

}

public struct ChatUpdatesProvider: ChatUpdatesProviderProtocol {
    public var updates: AnyAsyncSequence<(chatId: HandleEntity, connectionStatus: ChatConnectionStatus)> {
        AsyncStream { continuation in
            let delegate = ChatConnectionStateUpdateGlobalDelegate {
                continuation.yield(($0, $1))
            }
            continuation.onTermination = { _ in
                sdk.remove(delegate)
            }
            sdk.add(delegate, queueType: .globalBackground)
        }
        .eraseToAnyAsyncSequence()
    }
    
    public var chatOnlineUpdates: AnyAsyncSequence<(userHandle: HandleEntity, status: ChatStatusEntity, inProgress: Bool)> {
        AsyncStream { continuation in
            let delegate = ChatOnlineStatusUpdateGlobalDelegate {
                continuation.yield(($0, $1, $2))
            }
            continuation.onTermination = { _ in
                sdk.remove(delegate)
            }
            sdk.add(delegate, queueType: .globalBackground)
        }
        .eraseToAnyAsyncSequence()
    }
    
    public var presenceLastGreenUpdates: AnyAsyncSequence<(userHandle: HandleEntity, lastGreen: Int)> {
        AsyncStream { continuation in
            let delegate = ChatPresenceLastGreenUpdateGlobalDelegate {
                continuation.yield(($0, $1))
            }
            continuation.onTermination = { _ in
                sdk.remove(delegate)
            }
            sdk.add(delegate, queueType: .globalBackground)
        }
        .eraseToAnyAsyncSequence()
    }
    
    private let sdk: MEGAChatSdk
    
    public init(sdk: MEGAChatSdk) {
        self.sdk = sdk
    }
}

private class ChatConnectionStateUpdateGlobalDelegate: NSObject, MEGAChatDelegate {
    private let onChatConnectionStateUpdate: (HandleEntity, ChatConnectionStatus) -> Void
    
    init(onUpdate: @escaping (HandleEntity, ChatConnectionStatus) -> Void) {
        self.onChatConnectionStateUpdate = onUpdate
        super.init()
    }

    func onChatConnectionStateUpdate(_ api: MEGAChatSdk, chatId: UInt64, newState: Int32) {
        guard let chatConnection = MEGAChatConnection(rawValue: Int(newState)) else {
            return
        }
        onChatConnectionStateUpdate(chatId, chatConnection.toChatConnectionStatus())
    }
}
    
private class ChatOnlineStatusUpdateGlobalDelegate: NSObject, MEGAChatDelegate {
    private let onChatOnlineStatusUpdate: (HandleEntity, ChatStatusEntity, Bool) -> Void
    
    init(onChatOnlineStatusUpdate: @escaping (HandleEntity, ChatStatusEntity, Bool) -> Void) {
        self.onChatOnlineStatusUpdate = onChatOnlineStatusUpdate
        super.init()
    }
    
    func onChatOnlineStatusUpdate(_ api: MEGAChatSdk, userHandle: UInt64, status onlineStatus: MEGAChatStatus, inProgress: Bool) {
        onChatOnlineStatusUpdate(userHandle, onlineStatus.toChatStatusEntity(), inProgress)
    }
}

private class ChatPresenceLastGreenUpdateGlobalDelegate: NSObject, MEGAChatDelegate {
    private let onChatPresenceLastGreenUpdate: (HandleEntity, Int) -> Void
    
    init(onChatPresenceLastGreenUpdate: @escaping (HandleEntity, Int) -> Void) {
        self.onChatPresenceLastGreenUpdate = onChatPresenceLastGreenUpdate
        super.init()
    }
    
    func onChatPresenceLastGreen(_ api: MEGAChatSdk, userHandle: UInt64, lastGreen: Int) {
        onChatPresenceLastGreenUpdate(userHandle, lastGreen)
    }
}
