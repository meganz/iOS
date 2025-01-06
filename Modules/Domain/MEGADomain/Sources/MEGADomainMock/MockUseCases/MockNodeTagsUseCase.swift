import MEGADomain

@MainActor
public final class MockNodeTagsUseCase: NodeTagsUseCaseProtocol {
    public enum TagOperation: Equatable {
        case add(String)
        case remove(String)
    }
    public var _searchTags: [String]?
    public var _getTags: [String]?
    public private(set) var searchTexts: [String?] = []
    public private(set) var continuation: CheckedContinuation<[String]?, Never>?
    public private(set) var tagOperations: [TagOperation]  = []

    public init(searchTags: [String]? = nil, getTags: [String]? = nil) {
        _searchTags = searchTags
        _getTags = getTags
    }

    public func searchTags(for searchText: String?) async -> [String]? {
        searchTexts.append(searchText)
        if let _searchTags {
            return _searchTags
        } else {
            return await withCheckedContinuation { continuation in
                self.continuation = continuation
            }
        }
    }

    public func getTags(for node: NodeEntity) async -> [String]? {
        _getTags
    }

    public func add(tag: String, to node: NodeEntity) async throws {
        tagOperations.append(.add(tag))
    }

    public func remove(tag: String, from node: NodeEntity) async throws {
        tagOperations.append(.remove(tag))
    }
}
