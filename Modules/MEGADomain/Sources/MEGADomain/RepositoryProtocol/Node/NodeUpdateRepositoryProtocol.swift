import Foundation

public protocol NodeUpdateRepositoryProtocol: RepositoryProtocol {
    func shouldProcessOnNodesUpdate(parentNode: NodeEntity, childNodes: [NodeEntity],
                                    updatedNodes: [NodeEntity]) -> Bool
}
