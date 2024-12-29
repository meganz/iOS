import Foundation

public protocol NodeTagsRepositoryProtocol: RepositoryProtocol, Sendable {
    func searchTags(for searchText: String?) async -> [String]?
    func getTags(for node: NodeEntity) async -> [String]?
}
