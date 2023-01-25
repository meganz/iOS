import MEGADomain

protocol PhotoLibraryRepositoryProtocol: RepositoryProtocol {
    func photoSourceNode(for source: PhotoSourceEntity) async throws -> NodeEntity?
    func visualMediaNodes(inParent parentNode: NodeEntity?) -> [NodeEntity]
    func videoNodes(inParent parentNode: NodeEntity?) -> [NodeEntity]
}
