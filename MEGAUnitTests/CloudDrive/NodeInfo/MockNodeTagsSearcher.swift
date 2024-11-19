@testable import MEGA

actor MockNodeTagsSearcher: NodeTagsSearching {
    private let tags: [String]?

    init(tags: [String]? = nil) {
        self.tags = tags
    }

    func searchTags(for searchText: String?) async -> [String]? {
        tags
    }
}
