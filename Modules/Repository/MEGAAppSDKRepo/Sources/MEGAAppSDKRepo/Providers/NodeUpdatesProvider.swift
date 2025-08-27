import MEGADomain
import MEGASwift

public protocol NodeUpdatesProviderProtocol: Sendable {
    /// Node updates from `MEGAGlobalDelegate` `onNodesUpdate` as an `AnyAsyncSequence`
    var nodeUpdates: AnyAsyncSequence<[NodeEntity]> { get }
}

public struct NodeUpdatesProvider: NodeUpdatesProviderProtocol {
    public var nodeUpdates: AnyAsyncSequence<[NodeEntity]> {
        MEGAUpdateHandlerManager.shared.nodeUpdates
    }
    
    public init() {}
}
