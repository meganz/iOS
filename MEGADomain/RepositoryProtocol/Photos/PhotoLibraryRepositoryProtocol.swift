protocol PhotoLibraryRepositoryProtocol {
    func node(in source: PhotoSourceEntity) async throws -> MEGANode?
    func nodes(inParent parentNode: MEGANode?) -> [MEGANode]
}
