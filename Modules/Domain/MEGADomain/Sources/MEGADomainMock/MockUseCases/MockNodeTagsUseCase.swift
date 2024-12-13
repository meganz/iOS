import MEGADomain

@MainActor
public final class MockNodeTagsUseCase: NodeTagsUseCaseProtocol {
    private let tags: [String]?
    public private(set) var searchTexts: [String?] = []
    public private(set) var continuation: CheckedContinuation<[String]?, Never>?

    public init(tags: [String]? = nil) {
        self.tags = tags
    }

    public func searchTags(for searchText: String?) async -> [String]? {
        searchTexts.append(searchText)

        if let tags {
            return tags
        } else {
            return await withCheckedContinuation { continuation in
                self.continuation = continuation
            }
        }
    }
}
