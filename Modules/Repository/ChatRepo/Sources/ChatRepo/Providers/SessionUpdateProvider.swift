import MEGAChatSdk
import MEGADomain
import MEGASwift

public protocol SessionUpdateProviderProtocol: Sendable {
    /// Session updates from `MEGAChatCallDelegate` `onCallSessionUpdate` as an `AnyAsyncSequence`
    ///
    /// - Returns: `AnyAsyncSequence` that will call chatSdk.add on creation and chatSdk.remove onTermination of `AsyncStream`.
    /// It will yield `ChatSessionEntity, CallEntity` item until sequence terminated
    var sessionUpdate: AnyAsyncSequence<(ChatSessionEntity, CallEntity)> { get }
}

public struct SessionUpdateProvider: SessionUpdateProviderProtocol {
    public var sessionUpdate: AnyAsyncSequence<(ChatSessionEntity, CallEntity)> {
        AsyncStream { continuation in
            let delegate = SessionUpdateGlobalDelegate {
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

private final class SessionUpdateGlobalDelegate: NSObject, MEGAChatCallDelegate, Sendable {
    private let onSessionUpdate: @Sendable (ChatSessionEntity, CallEntity) -> Void
    
    public init(onUpdate: @Sendable @escaping (ChatSessionEntity, CallEntity) -> Void) {
        self.onSessionUpdate = onUpdate
        super.init()
    }

    func onChatSessionUpdate(_ api: MEGAChatSdk, chatId: UInt64, callId: UInt64, session: MEGAChatSession) {
        guard let call = api.chatCall(forCallId: callId) else { return }
        onSessionUpdate(session.toChatSessionEntity(), call.toCallEntity())
    }
}
