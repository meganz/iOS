import MEGAAnalyticsDomain

public final class MockViewIDRepository: ViewIDRepositoryProtocol, @unchecked Sendable {
    public static var newRepo: MockViewIDRepository {
        MockViewIDRepository()
    }
    
    public var _generateViewId: ViewID?
    
    public init(generateViewId: ViewID? = "view-id") {
        self._generateViewId = generateViewId
    }

    public func generateViewId() -> ViewID? {
        _generateViewId
    }
}
