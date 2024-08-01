import Combine
import MEGADomain
import MEGASdk
import MEGASDKRepo
import MEGASwift
import Search

protocol CloudDriveNodeSourceUpdatesListening {
    var nodeSourcePublisher: AnyPublisher<NodeSource, Never> { get }
    func startListening()
    func stopListening()
}

/// Contained a publisher that acts as the to a single source of truth for NodeSource of a NewCD page
/// Clients can listen to changes of NodeSource and react coresspondingly.
/// Examples of usage:
///     - When the current folder is renamed, the title of the navigation bar should be updated
///     - When access level of a incoming shared folder changes (e.g: from Full Access to Read only), we the "+" button should be hidden
///     - When Sharing status changed, the actions on the ",,," context menu on navigation bar should be updated accordingly.
///
final class NewCloudDriveNodeSourceUpdatesListener: CloudDriveNodeSourceUpdatesListening {
    private enum RunningState {
        case notStarted
        case active // Listening to sdk and will publish NodeSource changes
        case inactive(pendingNodesUpdate: [NodeEntity]?) // Still listening to SDK, but will defer latest NodeSource change until it's active again.
    }
    
    private let _nodeSourceSubject = PassthroughSubject<NodeSource, Never>()
    
    var nodeSourcePublisher: AnyPublisher<NodeSource, Never> {
        _nodeSourceSubject.eraseToAnyPublisher()
    }
    
    private let originalNodeSource: NodeSource
    private var nodeUpdatesListener: any NodesUpdateListenerProtocol
    
    @Atomic
    private var runningState: RunningState = .notStarted
    
    init(
        originalNodeSource: NodeSource,
        nodeUpdatesListener: some NodesUpdateListenerProtocol
    ) {
        self.originalNodeSource = originalNodeSource
        self.nodeUpdatesListener = nodeUpdatesListener
        self.nodeUpdatesListener.onNodesUpdateHandler = { [weak self] updatedNodes in
            self?.consumeNodeUpdates(updatedNodes)
        }
    }
    
    // To be called when the client needs to listening to NodeSource updates
    func startListening() {
        if case let .inactive(pendingNodesUpdate) = runningState, let pendingNodesUpdate {
            processNodeUpdates(pendingNodesUpdate)
        }
        $runningState.mutate { $0 = .active }
    }
    
    /// To be called when the client no longer needs to listening to NodeSource updates
    /// Note: After stopping, self is still receiving node updates from sdk and if there is any NodeSource update that needs
    /// to be emitted, the most-updated update will be deferred until the next call of `startListening()`
    /// This mechanism is needed because when CD screen is not not visible it should not update it's UI until it appears again
    /// (e.g: When a CD screen is not top of navigation stack, it shouldn't update the navigation bar items, because navigation bar is common used
    /// by all VC in the stacks, only the top VC in the stack should update the navigation bar)
    func stopListening() {
        $runningState.mutate { $0 = .inactive(pendingNodesUpdate: nil) }
    }
    
    private func consumeNodeUpdates(_ updatedNodes: [NodeEntity]) {
        switch runningState {
        case .notStarted: break
        case .active:
            processNodeUpdates(updatedNodes)
        case .inactive:
            $runningState.mutate { $0 = .inactive(pendingNodesUpdate: updatedNodes) }
        }
    }
    
    private func processNodeUpdates(_ updatedNodes: [NodeEntity]) {
        // Here we only handle nodeSource updates for .node case for now
        // if .recentActionBucket also needs to be handled we'll address it in [SAO-1153]
        guard case let .node(nodeProvider) = originalNodeSource else { return }
        
        if let parentNodeEntity = nodeProvider(),
           let updatedParentNode = updatedNodes.first(where: { $0.handle == parentNodeEntity.handle }) {
            let updatedNodeSource = NodeSource.node { updatedParentNode }
            _nodeSourceSubject.send(updatedNodeSource)
        }
    }
}
