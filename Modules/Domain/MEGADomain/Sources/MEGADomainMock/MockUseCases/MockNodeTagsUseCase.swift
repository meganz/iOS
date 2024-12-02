import MEGADomain

@MainActor
public final class MockNodeTagsUseCase: NodeTagsUseCaseProtocol {
    private let tags: [String]?
    public private(set) var searchTexts: [String?] = []

    public init(tags: [String]? = nil) {
        self.tags = tags
    }

    public func searchTags(for searchText: String?) async -> [String]? {
        searchTexts.append(searchText)
        return tags
    }
}
