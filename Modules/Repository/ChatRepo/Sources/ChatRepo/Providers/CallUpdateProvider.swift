import MEGAChatSdk
import MEGADomain
import MEGASwift

public protocol CallUpdateProviderProtocol: Sendable {
    /// Call updates from `MEGAChatCallDelegate` `onCallUpdate` as an `AnyAsyncSequence`
    ///
    /// - Returns: `AnyAsyncSequence` that will call chatSdk.add on creation and chatSdk.remove onTermination of `AsyncStream`.
    /// It will yield `CallEntity` item until sequence terminated
    var callUpdate: AnyAsyncSequence<CallEntity> { get }
}

public struct CallUpdateProvider: CallUpdateProviderProtocol {
    public var callUpdate: AnyAsyncSequence<CallEntity> {
        AsyncStream { continuation in
            let delegate = CallUpdateGlobalDelegate {
                continuation.yield($0)
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

private final class CallUpdateGlobalDelegate: NSObject, MEGAChatCallDelegate, Sendable {
    private let onCallUpdate: @Sendable (CallEntity) -> Void
    
    public init(onUpdate: @Sendable @escaping (CallEntity) -> Void) {
        self.onCallUpdate = onUpdate
        super.init()
    }

    func onChatCallUpdate(_ api: MEGAChatSdk, call: MEGAChatCall) {
        onCallUpdate(call.toCallEntity())
    }
}
