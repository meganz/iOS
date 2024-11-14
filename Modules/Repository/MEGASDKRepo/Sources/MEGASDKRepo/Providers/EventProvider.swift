import MEGADomain
import MEGASdk
import MEGASwift

public protocol EventProviderProtocol: Sendable {
    /// Event update from `MEGAGlobalDelegate` `onEvent` as an `AnyAsyncSequence`
    ///
    /// - Returns: `AnyAsyncSequence` that will call sdk.add on creation and sdk.remove onTermination of `AsyncStream`.
    /// It will yield `EventEntity` items until sequence terminated
    var event: AnyAsyncSequence<EventEntity> { get }
}

public struct EventProvider: EventProviderProtocol {
    public var event: AnyAsyncSequence<EventEntity> {
        AsyncStream { continuation in
            let delegate = EventGlobalDelegate {
                continuation.yield($0)
            }
            
            sdk.add(delegate)
            
            continuation.onTermination = { @Sendable _ in
                sdk.remove(delegate)
            }
        }
        .eraseToAnyAsyncSequence()
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
}

private final class EventGlobalDelegate: NSObject, MEGAGlobalDelegate, Sendable {
    private let onEvent: @Sendable (EventEntity) -> Void
    
    public init(onEvent: @Sendable @escaping (EventEntity) -> Void) {
        self.onEvent = onEvent
        super.init()
    }
    
    func onEvent(_ api: MEGASdk, event: MEGAEvent) {
        onEvent(event.toEventEntity())
    }
}
