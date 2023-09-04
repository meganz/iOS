public protocol NodeFavouriteActionRepositoryProtocol: RepositoryProtocol {
    func favourite(node: NodeEntity) async throws
    func unFavourite(node: NodeEntity) async throws
}
