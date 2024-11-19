import Foundation

public protocol NodeTagsRepositoryProtocol: Sendable {
    func searchTags(for searchText: String?) async -> [String]?
}
