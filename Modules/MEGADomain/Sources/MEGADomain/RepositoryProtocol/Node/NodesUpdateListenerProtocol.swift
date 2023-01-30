import Foundation

public protocol NodesUpdateListenerProtocol {
    var onNodesUpdateHandler: (([NodeEntity]) -> Void)? { get set }
}
