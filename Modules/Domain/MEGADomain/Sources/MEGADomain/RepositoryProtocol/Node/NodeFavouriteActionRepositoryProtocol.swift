public protocol NodeFavouriteActionRepositoryProtocol: RepositoryProtocol, Sendable {
    func favourite(node: NodeEntity) async throws
    func unFavourite(node: NodeEntity) async throws
}
