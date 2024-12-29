import MEGADomain

public final class MockNodeTagsRepository: NodeTagsRepositoryProtocol, @unchecked Sendable {
    public var _searchTags: [String]?
    public var _getTags: [String]?
    public func searchTags(for searchText: String?) async -> [String]? {
        _searchTags
    }
    
    public func getTags(for node: MEGADomain.NodeEntity) async -> [String]? {
        _getTags
    }

    init() {}

    public static var newRepo: Self {
        Self()
    }
}
