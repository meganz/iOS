import MEGADomain
import MEGASdk

public struct NodeUpdateRepository: NodeUpdateRepositoryProtocol {
    public static var newRepo: NodeUpdateRepository {
        NodeUpdateRepository()
    }
    
    public init() {}
    
    public func shouldProcessOnNodesUpdate(
        parentNode: NodeEntity,
        childNodes: [NodeEntity],
        updatedNodes: [NodeEntity]
    ) -> Bool {
        parentNode.shouldProcessOnNodeEntitiesUpdate(withChildNodes: childNodes, updatedNodes: updatedNodes)
    }
}
