import Foundation

public protocol ShareRepositoryProtocol: RepositoryProtocol, Sendable {
    func user(sharing node: NodeEntity) -> UserEntity?
    func allPublicLinks(sortBy order: SortOrderEntity) -> [NodeEntity]
    func allOutShares(sortBy order: SortOrderEntity) -> [ShareEntity]
    func areCredentialsVerifed(of user: UserEntity) -> Bool
    func createShareKey(forNode node: NodeEntity) async throws -> HandleEntity
    func isAnyCollectionShared() async -> Bool
    func unverifiedInShares() async -> [ShareEntity]
    func unverifiedOutShares() async -> [ShareEntity]
}
