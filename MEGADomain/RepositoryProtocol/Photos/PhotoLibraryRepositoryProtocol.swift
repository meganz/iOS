import MEGADomain

protocol PhotoLibraryRepositoryProtocol: RepositoryProtocol {
    func node(in source: PhotoSourceEntity) async throws -> MEGANode?
    func nodes(inParent parentNode: MEGANode?) -> [MEGANode]
    func videoNodes(inParent parentNode: MEGANode?) -> [MEGANode]
}
