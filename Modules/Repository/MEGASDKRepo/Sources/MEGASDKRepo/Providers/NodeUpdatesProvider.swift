import MEGADomain
import MEGASdk
import MEGASwift

public protocol NodeUpdatesProviderProtocol: Sendable {
    /// Node updates from `MEGAGlobalDelegate` `onNodesUpdate` as an `AnyAsyncSequence`
    ///
    /// - Returns: `AnyAsyncSequence` that will call sdk.add on creation and sdk.remove onTermination of `AsyncStream`. 
    /// It will yield `[NodeEntity]` items until sequence terminated
    var nodeUpdates: AnyAsyncSequence<[NodeEntity]> { get }
}

public struct NodeUpdatesProvider: NodeUpdatesProviderProtocol {
    public var nodeUpdates: AnyAsyncSequence<[NodeEntity]> {
        AsyncStream { continuation in
            let delegate = NodeUpdateGlobalDelegate {
                continuation.yield($0)
            }
            
            sdk.addMEGAGlobalDelegateAsync(delegate, queueType: .globalBackground)
            
            continuation.onTermination = { @Sendable _ in
                sdk.removeMEGAGlobalDelegateAsync(delegate)
            }
        }
        .eraseToAnyAsyncSequence()
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
}

private final class NodeUpdateGlobalDelegate: NSObject, MEGAGlobalDelegate, Sendable {
    private let onNodesUpdate: @Sendable ([NodeEntity]) -> Void
    
    public init(onUpdate: @Sendable @escaping ([NodeEntity]) -> Void) {
        self.onNodesUpdate = onUpdate
        super.init()
    }
    
    func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList?) {
        guard let nodesUpdates = nodeList?.toNodeEntities() else { return }
        onNodesUpdate(nodesUpdates)
    }
}
