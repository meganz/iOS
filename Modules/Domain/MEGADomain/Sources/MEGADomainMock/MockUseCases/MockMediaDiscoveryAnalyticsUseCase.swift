import MEGADomain

public final class MockMediaDiscoveryAnalyticsUseCase: MediaDiscoveryAnalyticsUseCaseProtocol {
    public var hasPageVisitedCalled: Bool
    public var hasPageStayCalled: Bool
    
    public init(
        hasPageVisitedCalled: Bool = false,
        hasPageStayCalled: Bool = false
    ) {
        self.hasPageVisitedCalled = hasPageVisitedCalled
        self.hasPageStayCalled = hasPageStayCalled
    }
    public func sendPageVisitedStats() {
        hasPageVisitedCalled = true
    }
    
    public func sendPageStayStats(with duration: Int) {
        hasPageStayCalled = true
    }
}
