public protocol NodeAttributeRepositoryProtocol: Sendable, RepositoryProtocol {
    func pathFor(node: NodeEntity) -> String?
    func numberChildrenFor(node: NodeEntity) -> Int
    func isInRubbishBin(node: NodeEntity) -> Bool
}
