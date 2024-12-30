import Foundation

public protocol NodeTagsRepositoryProtocol: RepositoryProtocol, Sendable {
    func searchTags(for searchText: String?) async -> [String]?
    func getTags(for node: NodeEntity) async -> [String]?
    func add(tag: String, to node: NodeEntity) async throws
    func remove(tag: String, from node: NodeEntity) async throws
}
