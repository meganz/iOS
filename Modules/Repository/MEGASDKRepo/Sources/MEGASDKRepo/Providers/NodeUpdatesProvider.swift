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
            continuation.onTermination = { @Sendable _ in
                sdk.remove(delegate)
            }
            sdk.add(delegate, queueType: .globalBackground)
        }
        .eraseToAnyAsyncSequence()
    }
    
    private let sdk: MEGASdk
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
}

private class NodeUpdateGlobalDelegate: NSObject, MEGAGlobalDelegate {
    private let onNodesUpdate: ([NodeEntity]) -> Void
    
    public init(onUpdate: @escaping ([NodeEntity]) -> Void) {
        self.onNodesUpdate = onUpdate
        super.init()
    }
    
    func onNodesUpdate(_ api: MEGASdk, nodeList: MEGANodeList?) {
        guard let nodesUpdates = nodeList?.toNodeEntities() else { return }
        onNodesUpdate(nodesUpdates)
    }
}
