import Foundation

public protocol NodesUpdateListenerProtocol: RepositoryProtocol {
    var onNodesUpdateHandler: (([NodeEntity]) -> Void)? { get set }
}
