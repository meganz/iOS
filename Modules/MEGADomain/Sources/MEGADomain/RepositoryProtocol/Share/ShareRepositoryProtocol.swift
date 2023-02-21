import Foundation

public protocol ShareRepositoryProtocol: RepositoryProtocol, Sendable {
    func user(sharing node: NodeEntity) -> UserEntity?
    func allPublicLinks(sortBy order: SortOrderEntity) -> [NodeEntity]
    func allOutShares(sortBy order: SortOrderEntity) -> [ShareEntity]
    func createShareKey(forNode node: NodeEntity) async throws -> HandleEntity
}
