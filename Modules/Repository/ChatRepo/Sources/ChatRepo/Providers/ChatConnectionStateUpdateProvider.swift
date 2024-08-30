import MEGAChatSdk
import MEGADomain
import MEGASwift

public protocol ChatConnectionStateUpdateProviderProtocol: Sendable {
    /// Call updates from `MEGAChatDelegate` `onChatConnectionStateUpdate` as an `AnyAsyncSequence`
    ///
    /// - Returns: `AnyAsyncSequence` that will call chatSdk.add on creation and chatSdk.remove onTermination of `AsyncStream`.
    /// It will yield `(HandleEntity, ChatConnectionStatus)` item until sequence terminated
    var updates: AnyAsyncSequence<(chatId: ChatIdEntity, connectionStatus: ChatConnectionStatus)> { get }
}

public struct ChatConnectionStateUpdateProvider: ChatConnectionStateUpdateProviderProtocol {
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
