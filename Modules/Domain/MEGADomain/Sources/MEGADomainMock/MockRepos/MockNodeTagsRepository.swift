import MEGADomain

public final class MockNodeTagsRepository: NodeTagsRepositoryProtocol, @unchecked Sendable {
    public var _searchTags: [String]?
    public var _getTags: [String]?
    public var _addTags: [String] = []
    public var _removeTags: [String] = []

    public func searchTags(for searchText: String?) async -> [String]? {
        _searchTags
    }
    
    public func getTags(for node: MEGADomain.NodeEntity) async -> [String]? {
        _getTags
    }

    public func add(tag: String, to node: NodeEntity) async throws {
        _addTags.append(tag)
    }

    public func remove(tag: String, from node: NodeEntity) async throws {
        _removeTags.append(tag)
    }

    init() {}

    public static var newRepo: Self {
        Self()
    }
}
