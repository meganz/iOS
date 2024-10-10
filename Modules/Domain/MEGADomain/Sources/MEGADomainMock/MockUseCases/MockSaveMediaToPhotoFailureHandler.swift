import MEGADomain

public final class MockSaveMediaToPhotoFailureHandler: SaveMediaToPhotoFailureHandling, @unchecked Sendable {
    public var fallback_calledTimes = 0
    private let shouldFallback: Bool
    
    public init(shouldFallback: Bool = true) {
        self.shouldFallback = shouldFallback
    }
    
    public func shouldFallbackToMakingOffline() async -> Bool {
        fallback_calledTimes += 1
        return shouldFallback
    }
}
