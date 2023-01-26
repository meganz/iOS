public protocol NodeFavouriteActionRepositoryProtocol {
    func favourite(node: NodeEntity) async throws
    func unFavourite(node: NodeEntity) async throws
}
