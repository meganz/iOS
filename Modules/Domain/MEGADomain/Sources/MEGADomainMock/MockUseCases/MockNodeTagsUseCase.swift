import MEGADomain

@MainActor
public final class MockNodeTagsUseCase: NodeTagsUseCaseProtocol {
    private let tags: [String]?
    public var numberOfCalls: Int = 0

    public init(tags: [String]? = nil) {
        self.tags = tags
    }

    public func searchTags(for searchText: String?) async -> [String]? {
        numberOfCalls += 1
        return tags
    }
}
