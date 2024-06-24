public protocol NodeUpdateRepositoryProtocol: RepositoryProtocol, Sendable {
    func shouldProcessOnNodesUpdate(parentNode: NodeEntity,
                                    childNodes: [NodeEntity],
                                    updatedNodes: [NodeEntity]) -> Bool
}
